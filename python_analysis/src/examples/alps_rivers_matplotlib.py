from __future__ import annotations

import argparse
from pathlib import Path
from time import perf_counter

import matplotlib
import numpy as np
import openeo
import xarray as xr


def log_step(step: str, start_time: float) -> None:
    elapsed = perf_counter() - start_time
    print(f"[{elapsed:7.2f}s] {step}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download Sentinel-2 data over Alps and open an interactive matplotlib NDWI explorer."
    )
    parser.add_argument("--west", type=float, default=11.293602)
    parser.add_argument("--east", type=float, default=11.382866)
    parser.add_argument("--south", type=float, default=46.460163)
    parser.add_argument("--north", type=float, default=46.514768)
    parser.add_argument("--start", type=str, default="2023-07-01")
    parser.add_argument("--end", type=str, default="2023-07-20")
    parser.add_argument("--cloud", type=float, default=20.0)
    parser.add_argument("--threshold", type=float, default=0.1)
    parser.add_argument("--force-download", action="store_true")
    parser.add_argument(
        "--no-gui",
        action="store_true",
        help="Skip interactive window and save debug PNG instead.",
    )
    return parser.parse_args()


def build_bbox(args: argparse.Namespace) -> dict:
    return {
        "west": args.west,
        "east": args.east,
        "south": args.south,
        "north": args.north,
        "crs": "EPSG:4326",
    }


def download_cube_if_needed(
    nc_path: Path,
    bbox: dict,
    start_date: str,
    end_date: str,
    max_cloud_cover: float,
    force_download: bool,
    t0: float,
) -> None:
    if nc_path.exists() and not force_download:
        log_step(f"Using cached NetCDF: {nc_path}", t0)
        return

    log_step("Connecting to openEO backend", t0)
    connection = openeo.connect("openeo.dataspace.copernicus.eu").authenticate_oidc()

    log_step("Building Sentinel-2 data cube (B03, B08)", t0)
    cube = connection.load_collection(
        "SENTINEL2_L2A",
        spatial_extent=bbox,
        temporal_extent=[start_date, end_date],
        bands=["B03", "B08"],
        max_cloud_cover=max_cloud_cover,
    )

    log_step("Downloading NetCDF from openEO", t0)
    cube.download(str(nc_path))
    log_step(f"Saved NetCDF: {nc_path}", t0)


def compute_ndwi(nc_path: Path, t0: float) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    log_step("Opening NetCDF with xarray", t0)
    ds = xr.open_dataset(nc_path)

    if "B03" not in ds.variables or "B08" not in ds.variables:
        raise RuntimeError("Expected variables B03 and B08 are not present in NetCDF.")

    log_step(
        f"Dataset variables: {list(ds.data_vars)} | dims: {dict(ds.sizes)}",
        t0,
    )

    green = ds["B03"].astype("float32")
    nir = ds["B08"].astype("float32")
    ndwi = (green - nir) / (green + nir)

    if "t" in ndwi.dims:
        log_step("Reducing time dimension with median composite", t0)
        ndwi2d = ndwi.median(dim="t", skipna=True)
    else:
        ndwi2d = ndwi

    arr = ndwi2d.values
    lons = ndwi2d["x"].values.astype(float)
    lats = ndwi2d["y"].values.astype(float)

    finite = np.isfinite(arr)
    if finite.any():
        log_step(
            "NDWI stats: min={:.3f}, max={:.3f}, mean={:.3f}".format(
                float(np.nanmin(arr)),
                float(np.nanmax(arr)),
                float(np.nanmean(arr)),
            ),
            t0,
        )
    else:
        raise RuntimeError("NDWI array contains only NaN values. Try a different date range/AOI.")

    return arr, lons, lats


def build_mask(arr: np.ndarray, threshold: float) -> np.ndarray:
    mask = np.zeros_like(arr, dtype=np.uint8)
    finite = np.isfinite(arr)
    mask[finite & (arr > threshold)] = 1
    return mask


def show_interactive(
    arr: np.ndarray,
    lons: np.ndarray,
    lats: np.ndarray,
    threshold: float,
    out_png: Path,
    no_gui: bool,
    t0: float,
) -> None:
    import matplotlib.pyplot as plt
    from matplotlib.widgets import Slider

    origin = "upper" if lats[0] > lats[-1] else "lower"
    extent = [float(lons.min()), float(lons.max()), float(lats.min()), float(lats.max())]

    fig, (ax_ndwi, ax_mask, ax_hist) = plt.subplots(1, 3, figsize=(14, 5))
    fig.subplots_adjust(bottom=0.20, wspace=0.30)

    ndwi_im = ax_ndwi.imshow(arr, cmap="RdBu", vmin=-1, vmax=1, origin=origin, extent=extent)
    ax_ndwi.set_title("NDWI")
    ax_ndwi.set_xlabel("Longitude")
    ax_ndwi.set_ylabel("Latitude")
    plt.colorbar(ndwi_im, ax=ax_ndwi, shrink=0.85)

    mask = build_mask(arr, threshold)
    mask_im = ax_mask.imshow(mask, cmap="Blues", vmin=0, vmax=1, origin=origin, extent=extent)
    ax_mask.set_title(f"Water mask (NDWI > {threshold:.2f})")
    ax_mask.set_xlabel("Longitude")
    ax_mask.set_ylabel("Latitude")
    plt.colorbar(mask_im, ax=ax_mask, shrink=0.85)

    values = arr[np.isfinite(arr)]
    ax_hist.hist(values, bins=80, color="gray", alpha=0.85)
    threshold_line = ax_hist.axvline(threshold, color="dodgerblue", linestyle="--", linewidth=2)
    ax_hist.set_title("NDWI histogram")
    ax_hist.set_xlabel("NDWI")
    ax_hist.set_ylabel("Pixel count")

    info_text = fig.text(0.64, 0.04, "", fontsize=10)

    def update_text(current_threshold: float, current_mask: np.ndarray) -> None:
        total = int(np.isfinite(arr).sum())
        water_pixels = int(current_mask.sum())
        pct = 100.0 * water_pixels / total if total > 0 else 0.0
        info_text.set_text(
            f"threshold={current_threshold:.3f} | water pixels={water_pixels}/{total} ({pct:.2f}%)"
        )

    update_text(threshold, mask)

    slider_ax = fig.add_axes([0.15, 0.08, 0.55, 0.04])
    slider = Slider(
        ax=slider_ax,
        label="NDWI threshold",
        valmin=-0.2,
        valmax=0.6,
        valinit=threshold,
        valstep=0.01,
    )

    def on_slide(val: float) -> None:
        current_mask = build_mask(arr, float(val))
        mask_im.set_data(current_mask)
        ax_mask.set_title(f"Water mask (NDWI > {val:.2f})")
        threshold_line.set_xdata([val, val])
        update_text(float(val), current_mask)
        fig.canvas.draw_idle()

    slider.on_changed(on_slide)

    if no_gui:
        log_step("No GUI mode: saving debug PNG", t0)
        fig.savefig(out_png, dpi=150)
        log_step(f"Saved debug plot: {out_png}", t0)
        plt.close(fig)
    else:
        log_step("Launching interactive matplotlib window", t0)
        plt.show()


def main() -> None:
    args = parse_args()
    t0 = perf_counter()

    if args.no_gui:
        matplotlib.use("Agg")
        log_step("Matplotlib backend: Agg (no GUI)", t0)
    else:
        matplotlib.use("TkAgg")
        log_step("Matplotlib backend: TkAgg (interactive window)", t0)

    data_dir = Path("/home/vsilv/.nextcloud/src/cassini/11th_cassini_hackathon/python_analysis/data")
    out_dir = Path("/home/vsilv/.nextcloud/src/cassini/11th_cassini_hackathon/python_analysis/figures")
    data_dir.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    nc_path = data_dir / "alps_s2_rivers.nc"
    out_png = out_dir / "alps_rivers_debug.png"

    bbox = build_bbox(args)
    log_step(
        (
            "AOI west={west:.5f}, east={east:.5f}, south={south:.5f}, north={north:.5f}, "
            "dates={start}..{end}, cloud<={cloud}%"
        ).format(
            west=bbox["west"],
            east=bbox["east"],
            south=bbox["south"],
            north=bbox["north"],
            start=args.start,
            end=args.end,
            cloud=args.cloud,
        ),
        t0,
    )

    download_cube_if_needed(
        nc_path=nc_path,
        bbox=bbox,
        start_date=args.start,
        end_date=args.end,
        max_cloud_cover=args.cloud,
        force_download=args.force_download,
        t0=t0,
    )

    arr, lons, lats = compute_ndwi(nc_path, t0)
    show_interactive(
        arr=arr,
        lons=lons,
        lats=lats,
        threshold=args.threshold,
        out_png=out_png,
        no_gui=args.no_gui,
        t0=t0,
    )
    log_step("Done", t0)


if __name__ == "__main__":
    main()
