from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import xarray as xr


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[2]
    p = argparse.ArgumentParser(description="Precompute lightweight Oetztal monthly time series to HDF5")
    p.add_argument("--start-year", type=int, default=2018)
    p.add_argument("--end-year", type=int, default=2024)
    p.add_argument(
        "--out",
        type=Path,
        default=root / "data" / "oetztal" / "oetztal_monthly_timeseries.h5",
    )
    return p.parse_args()


def get_time_name(ds: xr.Dataset) -> str:
    for c in ["t", "time", "date", "valid_time"]:
        if c in ds.coords or c in ds.dims:
            return c
    raise RuntimeError(f"No time coordinate found. coords={list(ds.coords)}, dims={list(ds.dims)}")


def area_monthly_series(da: xr.DataArray, time_name: str) -> pd.Series:
    s = da.mean(dim=[d for d in da.dims if d != time_name], skipna=True).to_series()
    s.index = pd.to_datetime(s.index)
    return s.resample("MS").median()


def save_hdf5(df: pd.DataFrame, out_file: Path) -> None:
    out_file.parent.mkdir(parents=True, exist_ok=True)
    if out_file.exists():
        out_file.unlink()

    ds = xr.Dataset(
        {
            "values": (
                ("time", "metric"),
                df.values.astype(np.float32),
            )
        },
        coords={
            "time": pd.to_datetime(df.index),
            "metric": df.columns.astype(str).tolist(),
        },
        attrs={
            "freq": "MS",
            "description": "Monthly AOI median time series derived from yearly S2 chunks",
        },
    )
    ds.to_netcdf(out_file, engine="netcdf4")
    ds.close()


def main() -> None:
    args = parse_args()

    root = Path(__file__).resolve().parents[2]
    data_dir = root / "data" / "oetztal"
    parts = [data_dir / f"oetztal_s2_{y}-01-01_{y}-12-31.nc" for y in range(args.start_year, args.end_year + 1)]

    missing = [p for p in parts if not p.exists()]
    if missing:
        raise RuntimeError(f"Missing yearly files: {missing}")

    valid_scl = [4, 5, 6, 11]
    monthly_parts: list[pd.DataFrame] = []

    for path in parts:
        print(f"Processing {path.name}")
        ds = xr.open_dataset(path, engine="netcdf4")
        tname = get_time_name(ds)

        valid = xr.zeros_like(ds["SCL"], dtype=bool)
        for v in valid_scl:
            valid = valid | (ds["SCL"] == v)

        ndvi = ((ds["B08"] - ds["B04"]) / (ds["B08"] + ds["B04"])).where(valid)
        ndwi = ((ds["B03"] - ds["B08"]) / (ds["B03"] + ds["B08"])).where(valid)
        ndsi = ((ds["B03"] - ds["B11"]) / (ds["B03"] + ds["B11"])).where(valid)

        snow_frac = (ndsi > 0.4).astype(np.float32)
        water_frac = (ndwi > 0.1).astype(np.float32)

        part_df = pd.DataFrame(
            {
                "NDVI": area_monthly_series(ndvi, tname),
                "NDWI": area_monthly_series(ndwi, tname),
                "NDSI": area_monthly_series(ndsi, tname),
                "SnowFrac": area_monthly_series(snow_frac, tname),
                "WaterFrac": area_monthly_series(water_frac, tname),
            }
        )
        monthly_parts.append(part_df)
        ds.close()

    out_df = pd.concat(monthly_parts).sort_index()
    out_df = out_df.groupby(out_df.index).median().sort_index()
    save_hdf5(out_df, args.out)

    size_kb = args.out.stat().st_size / 1024.0
    print(f"Saved: {args.out}")
    print(f"Rows: {len(out_df)}, Cols: {len(out_df.columns)}, Size: {size_kb:.1f} KiB")


if __name__ == "__main__":
    main()
