from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import xarray as xr


def frac_year(index: pd.DatetimeIndex) -> np.ndarray:
    return np.asarray(index.year + (index.month - 0.5) / 12.0, dtype=float)


def main() -> None:
    root = Path(__file__).resolve().parents[2]
    h5 = root / "data" / "oetztal" / "oetztal_monthly_timeseries.h5"

    ds = xr.open_dataset(h5, engine="netcdf4")
    df = pd.DataFrame(
        ds["values"].values,
        index=pd.to_datetime(ds["time"].values),
        columns=[str(v) for v in ds["metric"].values],
    ).sort_index()
    ds.close()

    snow = df["SnowFrac"].dropna().astype(float)
    snow_train = snow.resample("MS").mean().interpolate(method="time", limit_direction="both")
    future_idx = pd.date_range(snow_train.index.max() + pd.offsets.MonthBegin(1), "2050-12-01", freq="MS")

    x_train = frac_year(snow_train.index)
    max_per_year = snow_train.resample("YS").max()
    x_max = frac_year(max_per_year.index)
    m_env, b_env = np.polyfit(x_max, max_per_year.values, 1)
    m_env = float(min(m_env, -1e-4))

    env_train = m_env * x_train + b_env
    b_env = b_env + float(np.max(snow_train.values - env_train) + 0.02)

    x_future = frac_year(future_idx)
    env_future = np.asarray(np.clip(m_env * x_future + b_env, 0.01, 1.0), dtype=float)

    phase = 0.0
    season_future = 0.5 * (1.0 + np.sin(2 * np.pi * x_future + phase))
    snow_fore_mean = np.asarray(env_future * season_future, dtype=float)

    # mutability test (this failed in notebook before fix)
    snow_fore_mean[0] = float(snow_train.iloc[-1])

    print("OK: forecast array is mutable")
    print("first values:", snow_fore_mean[:3])


if __name__ == "__main__":
    main()
