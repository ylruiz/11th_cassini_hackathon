from __future__ import annotations

import argparse
from pathlib import Path
from time import perf_counter
from time import sleep

import numpy as np
import openeo
import pandas as pd
import xarray as xr


def log(msg: str, t0: float) -> None:
    print(f"[{perf_counter() - t0:8.1f}s] {msg}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="S2-only chunked fetch test for Oetztal trends")
    p.add_argument("--lat", type=float, default=46.83)
    p.add_argument("--lon", type=float, default=10.78)
    p.add_argument("--half-size", type=float, default=0.08)
    p.add_argument("--start", type=str, default="2018-01-01")
    p.add_argument("--end", type=str, default="2024-12-31")
    p.add_argument("--cloud", type=float, default=80.0)
    p.add_argument("--force", action="store_true")
    p.add_argument("--retries", type=int, default=2)
    p.add_argument("--poll", type=int, default=20, help="Batch status polling interval (seconds)")
    p.add_argument("--skip-merge", action="store_true", help="Skip writing merged multi-year file")
    return p.parse_args()


def year_chunks(start: str, end: str) -> list[tuple[str, str]]:
    s = pd.Timestamp(start)
    e = pd.Timestamp(end)
    out: list[tuple[str, str]] = []
    for y in range(s.year, e.year + 1):
        ys = pd.Timestamp(f"{y}-01-01")
        ye = pd.Timestamp(f"{y}-12-31")
        cs = max(s, ys)
        ce = min(e, ye)
        if cs <= ce:
            out.append((cs.strftime("%Y-%m-%d"), ce.strftime("%Y-%m-%d")))
    return out


def get_time_name(ds: xr.Dataset) -> str:
    for c in ["t", "time", "date", "valid_time"]:
        if c in ds.coords or c in ds.dims:
            return c
    raise RuntimeError(f"No time coordinate found. coords={list(ds.coords)} dims={list(ds.dims)}")


def is_valid_netcdf(path: Path) -> bool:
    if not path.exists() or path.stat().st_size == 0:
        return False
    try:
        ds = xr.open_dataset(path, engine="netcdf4")
        ds.close()
        return True
    except Exception:
        return False


def batch_download_with_retries(cube, out_file: Path, label: str, retries: int, poll_s: int, t0: float) -> None:
    last_exc = None
    for i in range(1, retries + 1):
        try:
            log(f"{label}: batch attempt {i}/{retries}", t0)
            job = cube.create_job(out_format="NetCDF", title=label)
            log(f"{label}: created job {job.job_id}", t0)
            job.start_job()
            log(f"{label}: started job {job.job_id}", t0)

            last_status = None
            while True:
                meta = job.describe_job()
                status = meta.get("status", "unknown")
                if status != last_status:
                    log(f"{label}: status={status}", t0)
                    last_status = status
                if status == "finished":
                    break
                if status in {"error", "canceled"}:
                    raise RuntimeError(f"{label}: job {job.job_id} ended with status={status}")
                sleep(poll_s)

            job.get_results().download_file(target=str(out_file))
            log(f"{label}: downloaded -> {out_file.name}", t0)
            return
        except Exception as exc:
            last_exc = exc
            log(f"{label}: failed attempt {i}: {exc}", t0)
    raise RuntimeError(f"{label}: all retries failed") from last_exc


def merge_parts(parts: list[Path], target: Path, t0: float) -> None:
    log(f"Merging {len(parts)} parts into {target.name}", t0)
    total_bytes = sum(p.stat().st_size for p in parts if p.exists())
    log(f"Merge input size: {total_bytes / (1024**3):.2f} GiB", t0)

    opened = []
    for i, p in enumerate(parts, start=1):
        log(f"Opening part {i}/{len(parts)}: {p.name}", t0)
        opened.append(xr.open_dataset(p, engine="netcdf4"))

    tname = get_time_name(opened[0])
    log("Concatenating parts in memory", t0)
    ds = xr.concat(opened, dim=tname)

    log(f"Sorting and deduplicating time coordinate: {tname}", t0)
    ds = ds.sortby(tname)
    idx = pd.Index(pd.to_datetime(ds[tname].values))
    keep = ~idx.duplicated()
    ds = ds.isel({tname: np.where(keep)[0]})

    if target.exists():
        target.unlink()
    log(f"Writing merged output to disk: {target.name}", t0)
    ds.to_netcdf(target)

    for ds_i in opened:
        ds_i.close()
    ds.close()
    log(f"Saved merged file: {target}", t0)


def main() -> None:
    args = parse_args()
    t0 = perf_counter()

    root = Path("/home/vsilv/.nextcloud/src/cassini/11th_cassini_hackathon/python_analysis")
    data_dir = root / "data" / "oetztal"
    data_dir.mkdir(parents=True, exist_ok=True)

    bbox = {
        "west": args.lon - args.half_size,
        "east": args.lon + args.half_size,
        "south": args.lat - args.half_size,
        "north": args.lat + args.half_size,
        "crs": "EPSG:4326",
    }

    s2_file = data_dir / f"oetztal_s2_{args.start}_{args.end}.nc"
    chunks = year_chunks(args.start, args.end)
    s2_parts = [data_dir / f"oetztal_s2_{cs}_{ce}.nc" for cs, ce in chunks]

    log(f"AOI bbox={bbox}", t0)
    log(f"Time range {args.start}..{args.end} ({len(chunks)} yearly chunks)", t0)

    if s2_file.exists() and not is_valid_netcdf(s2_file):
        log(f"Invalid/corrupted merged S2 file, removing: {s2_file.name}", t0)
        s2_file.unlink()

    log("Connecting to openEO backend", t0)
    conn = openeo.connect("openeo.dataspace.copernicus.eu").authenticate_oidc()

    for (cs, ce), part in zip(chunks, s2_parts):
        if part.exists() and not is_valid_netcdf(part):
            log(f"Invalid/corrupted S2 chunk, removing: {part.name}", t0)
            part.unlink()
        if part.exists() and not args.force:
            log(f"Using cached S2 chunk: {part.name}", t0)
            continue

        s2 = conn.load_collection(
            "SENTINEL2_L2A",
            spatial_extent=bbox,
            temporal_extent=[cs, ce],
            bands=["B03", "B04", "B08", "B11", "SCL"],
            max_cloud_cover=args.cloud,
        )
        batch_download_with_retries(s2, part, f"S2 {cs}..{ce}", args.retries, args.poll, t0)

    if args.skip_merge:
        log("Skipping merge (--skip-merge enabled)", t0)
        log("Fetch test completed successfully (chunks ready)", t0)
        return

    merge_parts(s2_parts, s2_file, t0)

    ds = xr.open_dataset(s2_file, engine="netcdf4")
    tname = get_time_name(ds)
    valid_mask = xr.zeros_like(ds["SCL"], dtype=bool)
    for v in [4, 5, 6, 11]:
        valid_mask = valid_mask | (ds["SCL"] == v)

    ndsi = ((ds["B03"] - ds["B11"]) / (ds["B03"] + ds["B11"])).where(valid_mask)
    snow_frac = (ndsi > 0.4).astype(float)
    snow_series = snow_frac.mean(dim=[d for d in snow_frac.dims if d != tname], skipna=True).to_series()
    snow_series.index = pd.to_datetime(snow_series.index)
    snow_m = snow_series.resample("MS").median()

    log(f"Merged S2 dims: {dict(ds.sizes)}", t0)
    log(f"Monthly snow frac points: {snow_m.notna().sum()} | mean={float(snow_m.mean()):.4f}", t0)
    ds.close()
    log("S2 fetch test completed successfully", t0)


if __name__ == "__main__":
    main()
