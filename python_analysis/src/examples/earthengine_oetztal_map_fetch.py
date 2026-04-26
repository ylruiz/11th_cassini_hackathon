from __future__ import annotations

import argparse
import os
from pathlib import Path
from time import perf_counter
from time import sleep

import matplotlib.pyplot as plt
import numpy as np
import openeo
from PIL import Image


def log(msg: str, t0: float) -> None:
    print(f"[{perf_counter() - t0:7.1f}s] {msg}")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Fetch Oetztal monthly S1 RGB map from openEO Earth Engine backend")
    p.add_argument("--backend", default="https://earthengine.openeo.org/v1.0")
    p.add_argument("--collection", default="COPERNICUS/S1_GRD")
    p.add_argument("--band", default="VV")
    p.add_argument("--lat", type=float, default=46.83)
    p.add_argument("--lon", type=float, default=10.78)
    p.add_argument("--half-size", type=float, default=0.08)
    p.add_argument("--march", default="2024-03-01")
    p.add_argument("--april", default="2024-04-01")
    p.add_argument("--may", default="2024-05-01")
    p.add_argument("--june", default="2024-06-01")
    p.add_argument("--user", default=os.getenv("OPENEO_EE_USER", ""))
    p.add_argument("--password", default=os.getenv("OPENEO_EE_PASSWORD", ""))
    p.add_argument("--no-oidc-fallback", action="store_true")
    p.add_argument("--poll", type=int, default=10)
    p.add_argument("--force", action="store_true")
    return p.parse_args()


def auth_connection(
    conn: openeo.Connection,
    user: str,
    password: str,
    no_oidc_fallback: bool,
    t0: float,
) -> openeo.Connection:
    if user and password:
        try:
            log("Trying basic authentication", t0)
            conn.authenticate_basic(user, password)
            log("Basic authentication succeeded", t0)
            return conn
        except Exception as exc:
            log(f"Basic authentication failed: {exc}", t0)
    if no_oidc_fallback:
        raise RuntimeError(
            "Authentication failed with username/password and --no-oidc-fallback is set. "
            "Provide valid OPENEO_EE_USER/OPENEO_EE_PASSWORD or remove --no-oidc-fallback."
        )
    log("Falling back to OIDC device flow", t0)
    conn.authenticate_oidc()
    log("OIDC authentication succeeded", t0)
    return conn


def run_month_job(
    conn: openeo.Connection,
    collection: str,
    band: str,
    bbox: dict,
    start: str,
    end: str,
    out_dir: Path,
    poll_s: int,
    force: bool,
    t0: float,
) -> Path:
    out_file = out_dir / f"{start}_{end}_{band}.png"
    if out_file.exists() and not force:
        log(f"Using cached month image: {out_file}", t0)
        return out_file

    cube = conn.load_collection(
        collection,
        spatial_extent=bbox,
        temporal_extent=[start, end],
        bands=[band],
        fetch_metadata=False,
    )
    result = cube.mean_time().save_result(format="PNG")

    job = result.create_job(title=f"oetztal-{band}-{start}")
    job.start_job()
    log(f"Started job {job.job_id} for {start}..{end}", t0)

    status = "created"
    while status not in {"finished", "error", "canceled"}:
        meta = job.describe_job()
        new_status = meta.get("status", "unknown")
        if new_status != status:
            status = new_status
            log(f"Job {job.job_id} status: {status}", t0)
        if status in {"finished", "error", "canceled"}:
            break
        sleep(poll_s)

    if status != "finished":
        raise RuntimeError(f"Job {job.job_id} failed with status={status}")

    month_dir = out_dir / f"job_{start}"
    month_dir.mkdir(parents=True, exist_ok=True)
    job.get_results().download_files(str(month_dir))
    pngs = sorted(month_dir.rglob("*.png"))
    if not pngs:
        raise RuntimeError(f"No PNG result found for job {job.job_id}")

    src = pngs[-1]
    out_file.write_bytes(src.read_bytes())
    log(f"Saved month image: {out_file}", t0)
    return out_file


def to_unit_gray(path: Path) -> np.ndarray:
    arr = np.asarray(Image.open(path).convert("L"), dtype=np.float32)
    lo = np.nanpercentile(arr, 2)
    hi = np.nanpercentile(arr, 98)
    if not np.isfinite(lo) or not np.isfinite(hi) or hi <= lo:
        return np.zeros_like(arr, dtype=np.float32)
    arr = (arr - lo) / (hi - lo)
    return np.clip(arr, 0, 1)


def main() -> None:
    args = parse_args()
    t0 = perf_counter()

    root = Path("/home/vsilv/.nextcloud/src/cassini/11th_cassini_hackathon/python_analysis")
    data_dir = root / "data" / "oetztal" / "earthengine_rgb"
    fig_dir = root / "figures"
    data_dir.mkdir(parents=True, exist_ok=True)
    fig_dir.mkdir(parents=True, exist_ok=True)

    bbox = {
        "west": args.lon - args.half_size,
        "south": args.lat - args.half_size,
        "east": args.lon + args.half_size,
        "north": args.lat + args.half_size,
    }
    log(f"Backend: {args.backend}", t0)
    log(f"Collection: {args.collection} | band={args.band}", t0)
    log(f"BBox: {bbox}", t0)

    conn = openeo.connect(args.backend)
    conn = auth_connection(conn, args.user, args.password, args.no_oidc_fallback, t0)

    march_png = run_month_job(
        conn,
        args.collection,
        args.band,
        bbox,
        args.march,
        args.april,
        data_dir,
        args.poll,
        args.force,
        t0,
    )
    april_png = run_month_job(
        conn,
        args.collection,
        args.band,
        bbox,
        args.april,
        args.may,
        data_dir,
        args.poll,
        args.force,
        t0,
    )
    may_png = run_month_job(
        conn,
        args.collection,
        args.band,
        bbox,
        args.may,
        args.june,
        data_dir,
        args.poll,
        args.force,
        t0,
    )

    r = to_unit_gray(march_png)
    g = to_unit_gray(april_png)
    b = to_unit_gray(may_png)
    rgb = np.dstack([r, g, b])

    fig, ax = plt.subplots(figsize=(8, 8), facecolor="white")
    ax.imshow(rgb)
    ax.set_title("Oetztal S1 monthly RGB (Mar/Apr/May)")
    ax.set_xticks([])
    ax.set_yticks([])
    plt.tight_layout()

    fig_path = fig_dir / "oetztal_s1_monthly_rgb_earthengine.png"
    fig.savefig(fig_path, dpi=180, bbox_inches="tight", facecolor="white")
    plt.close(fig)

    log(f"Saved RGB map: {fig_path}", t0)
    log("Done", t0)


if __name__ == "__main__":
    main()
