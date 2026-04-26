from __future__ import annotations

import argparse
from datetime import timedelta
from datetime import date as dt_date
from pathlib import Path
from time import perf_counter
from time import sleep

import matplotlib.pyplot as plt
import numpy as np
import openeo
import xarray as xr


def log(msg: str, t0: float) -> None:
    print(f"[{perf_counter() - t0:7.1f}s] {msg}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Fetch and plot Oetztal map from Copernicus openEO backend")
    p.add_argument("--backend", default="openeo.dataspace.copernicus.eu")
    p.add_argument("--collection", default="SENTINEL2_L2A")
    p.add_argument("--lat", type=float, default=46.83)
    p.add_argument("--lon", type=float, default=10.78)
    p.add_argument("--half-size", type=float, default=0.08)
    p.add_argument("--date", default="2024-08-15", help="Single snapshot day (YYYY-MM-DD)")
    p.add_argument("--window-days", type=int, default=3, help="Days before/after --date for cloud-free compositing")
    p.add_argument("--yearly-median", action="store_true", help="Use full year around --year (or year of --date)")
    p.add_argument("--year", type=int, default=None, help="Year used when --yearly-median is set")
    p.add_argument("--cloud", type=float, default=70.0)
    p.add_argument("--poll", type=int, default=15)
    p.add_argument("--retries", type=int, default=2)
    p.add_argument("--force", action="store_true")
    return p.parse_args()


def get_time_name(ds: xr.Dataset) -> str | None:
    for c in ["t", "time", "date", "valid_time"]:
        if c in ds.coords or c in ds.dims:
            return c
    return None


def normalize(arr: np.ndarray, q_low: float = 2.0, q_high: float = 98.0) -> np.ndarray:
    x = arr.astype(np.float32).copy()
    lo = np.nanpercentile(x, q_low)
    hi = np.nanpercentile(x, q_high)
    if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
        return np.zeros_like(x, dtype=np.float32)
    x = (x - lo) / (hi - lo)
    return np.clip(x, 0, 1)


def run_batch_download(cube, out_file: Path, poll_s: int, retries: int, t0: float) -> None:
    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            log(f"Batch attempt {attempt}/{retries}", t0)
            job = cube.create_job(out_format="NetCDF", title=f"oetztal-map-{out_file.stem}")
            log(f"Created job {job.job_id}", t0)
            job.start_job()
            log(f"Started job {job.job_id}", t0)

            status = "created"
            while status not in {"finished", "error", "canceled"}:
                meta = job.describe_job()
                new_status = meta.get("status", "unknown")
                if new_status != status:
                    status = new_status
                    log(f"Job status={status}", t0)
                if status in {"finished", "error", "canceled"}:
                    break
                sleep(poll_s)

            if status != "finished":
                raise RuntimeError(f"Job {job.job_id} ended with status={status}")

            job.get_results().download_file(target=str(out_file))
            log(f"Downloaded {out_file}", t0)
            return
        except Exception as exc:
            last_exc = exc
            log(f"Attempt {attempt} failed: {exc}", t0)

    raise RuntimeError("All batch download attempts failed") from last_exc


def main() -> None:
    args = parse_args()
    t0 = perf_counter()
    start_day = dt_date.fromisoformat(args.date)
    if args.yearly_median:
        year = args.year if args.year is not None else start_day.year
        start = dt_date(year, 1, 1).isoformat()
        end = dt_date(year + 1, 1, 1).isoformat()
        period_tag = f"y{year}"
    else:
        range_start = start_day - timedelta(days=args.window_days)
        range_end = start_day + timedelta(days=args.window_days + 1)
        start = range_start.isoformat()
        end = range_end.isoformat()
        period_tag = f"{args.date}_w{args.window_days}"

    root = Path("/home/vsilv/.nextcloud/src/cassini/11th_cassini_hackathon/python_analysis")
    data_dir = root / "data" / "oetztal"
    fig_dir = root / "figures"
    data_dir.mkdir(parents=True, exist_ok=True)
    fig_dir.mkdir(parents=True, exist_ok=True)

    bbox = {
        "west": args.lon - args.half_size,
        "east": args.lon + args.half_size,
        "south": args.lat - args.half_size,
        "north": args.lat + args.half_size,
        "crs": "EPSG:4326",
    }

    out_file = data_dir / (
        f"map_{args.collection}_{period_tag}_hs{args.half_size:.3f}_{args.lat:.3f}_{args.lon:.3f}.nc"
    )
    fig_file = fig_dir / f"oetztal_copernicus_snapshot_{period_tag}_hs{args.half_size:.3f}.png"

    log(f"Backend: {args.backend}", t0)
    log(f"Collection: {args.collection}", t0)
    log(f"BBox: {bbox}", t0)
    if args.yearly_median:
        log(f"Yearly median mode: {start} to {end} (exclusive end)", t0)
    else:
        log(f"Target day: {args.date}", t0)
        log(f"Cloud-removal window: {start} to {end} (exclusive end)", t0)

    if not out_file.exists() or args.force:
        log("Connecting/authenticating", t0)
        conn = openeo.connect(args.backend).authenticate_oidc()
        log("Building data cube", t0)
        cube = conn.load_collection(
            args.collection,
            spatial_extent=bbox,
            temporal_extent=[start, end],
            bands=["B02", "B03", "B04", "B08", "SCL"],
            max_cloud_cover=args.cloud,
        )
        run_batch_download(cube, out_file, poll_s=args.poll, retries=args.retries, t0=t0)
    else:
        log(f"Using cached file: {out_file}", t0)

    log("Reading NetCDF", t0)
    ds = xr.open_dataset(out_file, engine="netcdf4")
    tname = get_time_name(ds)
    band_ds = ds[["B02", "B03", "B04", "B08", "SCL"]]

    valid_classes = [4, 5, 6, 11]
    valid = xr.zeros_like(band_ds["SCL"], dtype=bool)
    for v in valid_classes:
        valid = valid | (band_ds["SCL"] == v)

    clear_ratio = float(valid.astype("float32").mean().item())
    log(f"Clear-pixel ratio in window: {clear_ratio:.3f}", t0)

    masked = band_ds[["B02", "B03", "B04", "B08"]].where(valid)
    comp = masked.median(dim=tname, skipna=True) if tname else masked

    r = comp["B04"].astype("float32")
    g = comp["B03"].astype("float32")
    b = comp["B02"].astype("float32")
    rgb = np.dstack([normalize(r.values), normalize(g.values), normalize(b.values)])

    ndwi = (
        (comp["B03"].astype("float32") - comp["B08"].astype("float32"))
        / (comp["B03"].astype("float32") + comp["B08"].astype("float32"))
    )
    water = (ndwi > 0.1).astype(np.uint8)

    fig, ax = plt.subplots(1, 3, figsize=(15, 5), facecolor="white")
    ax[0].imshow(rgb)
    ax[0].set_title("RGB median composite")
    ax[0].set_xticks([])
    ax[0].set_yticks([])

    cmap = plt.get_cmap("RdBu_r").copy()
    cmap.set_bad("lightgray")
    im1 = ax[1].imshow(ndwi, cmap=cmap)
    ax[1].set_title("NDWI")
    ax[1].set_xticks([])
    ax[1].set_yticks([])
    plt.colorbar(im1, ax=ax[1], shrink=0.8)

    im2 = ax[2].imshow(water, cmap="Blues", vmin=0, vmax=1)
    ax[2].set_title("Water mask (NDWI > 0.1)")
    ax[2].set_xticks([])
    ax[2].set_yticks([])
    plt.colorbar(im2, ax=ax[2], shrink=0.8)

    plt.tight_layout()
    fig.savefig(fig_file, dpi=160, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    ds.close()

    log(f"Saved figure: {fig_file}", t0)
    log("Done", t0)


if __name__ == "__main__":
    main()
