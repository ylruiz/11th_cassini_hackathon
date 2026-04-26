from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import xarray as xr


def frac_year(index: pd.DatetimeIndex) -> np.ndarray:
    return index.year + (index.month - 0.5) / 12.0


def design_logexp(index: pd.DatetimeIndex, t0: float) -> np.ndarray:
    t = frac_year(index) - t0
    return np.column_stack([np.ones_like(t), t])


def bayesian_linear_posterior_draws(
    y: np.ndarray,
    X: np.ndarray,
    X_future: np.ndarray,
    prior_var: np.ndarray,
    prior_mean: np.ndarray | None = None,
    n_samples: int = 5000,
    alpha0: float = 2.0,
    beta0: float = 0.05,
    seed: int = 42,
) -> tuple[np.ndarray, np.ndarray]:
    p = X.shape[1]
    v0_inv = np.diag(1.0 / prior_var.astype(float))
    m0 = np.zeros(p, dtype=float) if prior_mean is None else prior_mean.astype(float)

    vn = np.linalg.inv(v0_inv + X.T @ X)
    mn = vn @ (X.T @ y + v0_inv @ m0)

    an = alpha0 + 0.5 * len(y)
    bn = beta0 + 0.5 * (y @ y + m0.T @ v0_inv @ m0 - mn.T @ np.linalg.inv(vn) @ mn)

    rng = np.random.default_rng(seed)
    lam = rng.gamma(shape=an, scale=1.0 / bn, size=n_samples)
    sigma2 = 1.0 / lam
    L = np.linalg.cholesky(vn)

    fit_draws = np.empty((n_samples, X.shape[0]), dtype=np.float32)
    fore_draws = np.empty((n_samples, X_future.shape[0]), dtype=np.float32)
    for i in range(n_samples):
        w = mn + np.sqrt(sigma2[i]) * (L @ rng.standard_normal(p))
        fit_draws[i, :] = X @ w
        fore_draws[i, :] = X_future @ w
    return fit_draws, fore_draws


def summarize_draws(draws: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    return draws.mean(axis=0), np.quantile(draws, 0.05, axis=0), np.quantile(draws, 0.95, axis=0)


def design_snow_saturating(index: pd.DatetimeIndex, t_ref: float, k_decay: float = 0.10, n_harmonics: int = 4) -> np.ndarray:
    t = frac_year(index) - t_ref
    sat = 1.0 - np.exp(-k_decay * np.clip(t, 0.0, None))
    cols = [np.ones_like(t), t, sat]
    for k in range(1, n_harmonics + 1):
        cols.append(np.sin(2 * np.pi * k * t))
        cols.append(np.cos(2 * np.pi * k * t))
    return np.column_stack(cols)


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    h5 = root / "data" / "oetztal" / "oetztal_monthly_timeseries.h5"
    ds = xr.open_dataset(h5, engine="netcdf4")
    overview_df = pd.DataFrame(
        ds["values"].values,
        index=pd.to_datetime(ds["time"].values),
        columns=[str(v) for v in ds["metric"].values],
    ).sort_index()
    ds.close()

    forecast_end = pd.Timestamp("2050-12-01")
    n_samples = 3000

    snow_obs = overview_df["SnowFrac"].dropna().astype(float)
    snow_obs_monthly = snow_obs.resample("MS").mean()
    try:
        snow_train = snow_obs_monthly.interpolate(method="pchip", limit_direction="both")
        interp_method = "pchip"
    except Exception:
        snow_train = snow_obs_monthly.interpolate(method="time", limit_direction="both")
        interp_method = "time"

    future_idx = pd.date_range(snow_train.index.max() + pd.offsets.MonthBegin(1), forecast_end, freq="MS")
    t0 = float(np.mean(frac_year(snow_train.index)))

    snow_ref = float(frac_year(pd.DatetimeIndex([snow_train.index[0]]))[0])
    x_snow = design_snow_saturating(snow_train.index, t_ref=snow_ref)
    xf_snow = design_snow_saturating(future_idx, t_ref=snow_ref)

    obs_snow_slope = float(np.polyfit(frac_year(snow_train.index), snow_train.values, 1)[0])
    snow_target_2050 = 0.001
    last_snow = float(np.clip(snow_train.iloc[-1], 1e-4, 1.0))
    t_last = float(frac_year(pd.DatetimeIndex([snow_train.index[-1]]))[0] - snow_ref)
    t_end = float((forecast_end.year + (forecast_end.month - 0.5) / 12.0) - snow_ref)
    s_last = 1.0 - np.exp(-0.10 * max(t_last, 0.0))
    s_end = 1.0 - np.exp(-0.10 * max(t_end, 0.0))

    trend_prior_mean = 1.45 * obs_snow_slope
    sat_prior_mean = (snow_target_2050 - last_snow - trend_prior_mean * (t_end - t_last)) / max(s_end - s_last, 1e-6)
    intercept_prior_mean = last_snow - trend_prior_mean * t_last - sat_prior_mean * s_last

    snow_prior_var = np.array([0.25, 8e-5, 0.004, 0.55, 0.55, 0.30, 0.30, 0.18, 0.18, 0.12, 0.12], dtype=float)
    snow_prior_mean = np.array([intercept_prior_mean, trend_prior_mean, sat_prior_mean, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], dtype=float)

    snow_fit_draws, snow_fore_draws = bayesian_linear_posterior_draws(
        y=snow_train.values,
        X=x_snow,
        X_future=xf_snow,
        prior_var=snow_prior_var,
        prior_mean=snow_prior_mean,
        n_samples=n_samples,
        seed=7,
    )
    snow_fit_raw, _, _ = summarize_draws(snow_fit_draws)
    snow_fore_raw, _, _ = summarize_draws(snow_fore_draws)

    full_raw = np.concatenate([snow_fit_raw, snow_fore_raw])
    full_trend = pd.Series(full_raw).rolling(12, center=True, min_periods=1).mean().values
    full_osc = full_raw - full_trend
    full_h = np.linspace(0.0, 1.0, len(full_raw), dtype=np.float64)

    fit_amp_profile = np.clip(1.8 - 0.95 * full_h, 0.85, 1.8)
    pre = full_trend + fit_amp_profile * full_osc
    early_n = int(min(18, len(snow_fit_raw)))
    early_obs_q95 = float(np.nanquantile(snow_train.values[:early_n], 0.95))
    early_pre_q95 = float(np.nanquantile(pre[:early_n], 0.95))
    early_gain = float(np.clip((early_obs_q95 + 1e-6) / (early_pre_q95 + 1e-6), 1.0, 2.8))
    full_adj = full_trend + (early_gain * fit_amp_profile) * full_osc

    n_fit = len(snow_fit_raw)
    snow_fit_mean = full_adj[:n_fit]
    snow_fore_base = full_adj[n_fit:]
    snow_horizon = np.linspace(0.0, 1.0, len(future_idx), dtype=np.float64)
    snow_min_floor = 0.001

    fit_trend_hist = pd.Series(snow_fit_mean, index=snow_train.index).rolling(12, center=True, min_periods=1).mean().values
    fit_resid = snow_fit_mean - fit_trend_hist
    month_template = pd.Series(fit_resid, index=snow_train.index).groupby(snow_train.index.month).median()
    month_template = month_template - month_template.mean()
    osc_seed = np.array([float(month_template.get(m, 0.0)) for m in future_idx.month], dtype=float)

    tail_n = int(min(12, len(snow_fit_mean)))
    fit_tail_slope = float(np.mean(np.diff(snow_fit_mean[-tail_n:]))) if len(snow_fit_mean) >= 2 else 0.0
    fit_tail_resid_std = float(np.nanstd(fit_resid[-tail_n:])) if tail_n >= 2 else 0.0
    seed_resid_std = float(np.nanstd(osc_seed[:tail_n])) if tail_n >= 2 else 1.0
    amp0 = float(np.clip(1.2 * (fit_tail_resid_std + 1e-6) / (seed_resid_std + 1e-6), 0.7, 2.4))
    amp_decay = np.exp(-snow_horizon / 2.4)

    trend_seed = snow_fit_mean[-1] + fit_tail_slope * np.arange(len(future_idx), dtype=float)
    trend_target = snow_min_floor + (snow_fore_base - snow_min_floor) * np.exp(-1.8 * snow_horizon)
    blend = np.clip(np.arange(len(future_idx), dtype=float) / 36.0, 0.0, 1.0)
    blend = blend * blend * (3.0 - 2.0 * blend)
    trend_fore = (1.0 - blend) * trend_seed + blend * trend_target
    osc_fore = amp0 * amp_decay * osc_seed
    snow_fore_mean = trend_fore + osc_fore

    continuity_offset = float(snow_fit_mean[-1] - snow_fore_mean[0])
    snow_fore_mean = snow_fore_mean + continuity_offset * np.exp(-snow_horizon * 8.0)

    slope_fit = float(snow_fit_mean[-1] - snow_fit_mean[-2]) if len(snow_fit_mean) >= 2 else 0.0
    slope_fore0 = float(snow_fore_mean[1] - snow_fore_mean[0]) if len(snow_fore_mean) >= 2 else 0.0
    slope_delta = slope_fit - slope_fore0
    step_idx = np.arange(len(future_idx), dtype=float)
    slope_corr = slope_delta * step_idx * np.exp(-step_idx / 6.0)
    snow_fore_mean = snow_fore_mean + slope_corr

    snow_fit_mean = np.clip(snow_fit_mean, snow_min_floor, 1.0)
    snow_fore_mean = np.clip(snow_fore_mean, snow_min_floor, 1.0)

    gap0 = float(snow_fore_mean[0] - snow_fit_mean[-1])
    slope_fore = float(snow_fore_mean[1] - snow_fore_mean[0]) if len(snow_fore_mean) >= 2 else 0.0
    slope_gap = float(slope_fore - slope_fit)

    tail_amp = float(np.nanstd(fit_resid[-12:])) if len(fit_resid) >= 12 else float(np.nanstd(fit_resid))
    head_trend = pd.Series(snow_fore_mean).rolling(12, center=True, min_periods=1).mean().values
    head_amp = float(np.nanstd((snow_fore_mean - head_trend)[:12])) if len(snow_fore_mean) >= 12 else float(np.nanstd(snow_fore_mean - head_trend))

    print(f"Interpolation: {interp_method}")
    print(f"Gap at boundary: {gap0:.6f}")
    print(f"Slope gap at boundary: {slope_gap:.6f} (delta applied: {slope_delta:.6f})")
    print(f"Tail vs head oscillation std: {tail_amp:.4f} vs {head_amp:.4f}")
    print(f"Early gain: {early_gain:.3f}, amp0: {amp0:.3f}")
    print(f"Snow fit last / forecast first: {snow_fit_mean[-1]:.4f} / {snow_fore_mean[0]:.4f}")


if __name__ == "__main__":
    main()
