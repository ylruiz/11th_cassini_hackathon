from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import xarray as xr


def frac_year(index: pd.DatetimeIndex) -> np.ndarray:
    return index.year + (index.month - 0.5) / 12.0


def bayes_draws(
    y: np.ndarray,
    x_train: np.ndarray,
    x_eval: np.ndarray,
    prior_var: np.ndarray,
    prior_mean: np.ndarray,
    n_samples: int = 3000,
    seed: int = 7,
) -> tuple[np.ndarray, np.ndarray]:
    p = x_train.shape[1]
    v0_inv = np.diag(1.0 / prior_var.astype(float))
    vn = np.linalg.inv(v0_inv + x_train.T @ x_train)
    mn = vn @ (x_train.T @ y + v0_inv @ prior_mean)

    alpha0 = 2.0
    beta0 = 0.05
    an = alpha0 + 0.5 * len(y)
    bn = beta0 + 0.5 * (y @ y + prior_mean.T @ v0_inv @ prior_mean - mn.T @ np.linalg.inv(vn) @ mn)

    rng = np.random.default_rng(seed)
    lam = rng.gamma(shape=an, scale=1.0 / bn, size=n_samples)
    sigma2 = 1.0 / lam
    l = np.linalg.cholesky(vn)

    train_draws = np.empty((n_samples, x_train.shape[0]), dtype=np.float32)
    eval_draws = np.empty((n_samples, x_eval.shape[0]), dtype=np.float32)
    for i in range(n_samples):
        w = mn + np.sqrt(sigma2[i]) * (l @ rng.standard_normal(p))
        train_draws[i, :] = x_train @ w
        eval_draws[i, :] = x_eval @ w
    return train_draws, eval_draws


def design_snow(index: pd.DatetimeIndex, t0: float, k_decay: float = 0.10, n_harmonics: int = 4) -> np.ndarray:
    t = frac_year(index) - t0
    sat = 1.0 - np.exp(-k_decay * np.clip(t, 0.0, None))
    cols: list[np.ndarray] = [np.ones_like(t), t, t * t, sat]
    for k in range(1, n_harmonics + 1):
        s = np.sin(2 * np.pi * k * t)
        c = np.cos(2 * np.pi * k * t)
        cols.extend([s, c, t * s, t * c])
    return np.column_stack(cols)


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    data = root / "data" / "oetztal" / "oetztal_monthly_timeseries.h5"

    ds = xr.open_dataset(data, engine="netcdf4")
    df = pd.DataFrame(
        ds["values"].values,
        index=pd.to_datetime(ds["time"].values),
        columns=[str(v) for v in ds["metric"].values],
    ).sort_index()
    ds.close()

    snow_obs = df["SnowFrac"].dropna().astype(float)
    snow_obs_monthly = snow_obs.resample("MS").mean()
    try:
        snow_train = snow_obs_monthly.interpolate(method="pchip", limit_direction="both")
        interp = "pchip"
    except Exception:
        snow_train = snow_obs_monthly.interpolate(method="time", limit_direction="both")
        interp = "time"

    forecast_end = pd.Timestamp("2050-12-01")
    future_idx = pd.date_range(snow_train.index.max() + pd.offsets.MonthBegin(1), forecast_end, freq="MS")
    all_idx = snow_train.index.append(future_idx)

    t0 = float(np.mean(frac_year(snow_train.index)))
    x_train = design_snow(snow_train.index, t0=t0)
    x_all = design_snow(all_idx, t0=t0)

    obs_slope = float(np.polyfit(frac_year(snow_train.index), snow_train.values, 1)[0])
    p = x_train.shape[1]
    prior_mean = np.zeros(p, dtype=float)
    prior_var = np.ones(p, dtype=float)

    prior_mean[0] = 0.5
    prior_mean[1] = 1.15 * obs_slope
    prior_mean[3] = -0.15
    prior_var[0] = 0.4
    prior_var[1] = 8e-4
    prior_var[2] = 4e-4
    prior_var[3] = 0.08

    for i in range(4, p):
        prior_var[i] = 0.8

    fit_draws, all_draws = bayes_draws(
        y=snow_train.values,
        x_train=x_train,
        x_eval=x_all,
        prior_var=prior_var,
        prior_mean=prior_mean,
        n_samples=3000,
        seed=7,
    )

    all_mean = np.clip(all_draws.mean(axis=0), 0.001, 1.0)
    n_fit = len(snow_train)
    fit_mean = all_mean[:n_fit]
    fore_mean = all_mean[n_fit:]

    gap0 = float(fore_mean[0] - fit_mean[-1])
    slope_fit = float(fit_mean[-1] - fit_mean[-2])
    slope_fore = float(fore_mean[1] - fore_mean[0])

    print(f"interp={interp}")
    print(f"fit_last={fit_mean[-1]:.4f} fore_first={fore_mean[0]:.4f} gap={gap0:.6f}")
    print(f"slope_fit={slope_fit:.6f} slope_fore={slope_fore:.6f} slope_gap={(slope_fore - slope_fit):.6f}")
    print(f"fit_max={fit_mean.max():.4f} fit_min={fit_mean.min():.4f}")
    print(f"fore_2050={fore_mean[-1]:.4f}")


if __name__ == "__main__":
    main()
