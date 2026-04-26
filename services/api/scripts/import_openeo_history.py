"""Import an openEO Sentinel-2 (+ optional EFAS) export into
``services/api/app/data/aoi_history.json``.

The format expected by this script is documented in
``python_analysis/openeo_history_format.md``. The script accepts CSV or JSON
files and prints a short summary on success.

Usage::

    cd services/api
    python scripts/import_openeo_history.py path/to/openeo_history.csv

    # remap a non-canonical AOI identifier produced by the colleague's
    # notebook to the slug the API uses
    python scripts/import_openeo_history.py \\
        --alias "oetztal_2024_v3=oetztal-alps" \\
        path/to/openeo_history.csv

    # dry-run: show what would be written without touching disk
    python scripts/import_openeo_history.py --dry-run path/to/openeo_history.csv

The output is the same JSON shape produced by ``generate_baked_history.py``,
which is what ``GET /risk-timeline/aoi/history`` already serves.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

OUTPUT_PATH = (
    Path(__file__).resolve().parents[1] / "app" / "data" / "aoi_history.json"
)

# Canonical AOI slug -> (display label, aliases the API will match against).
KNOWN_AOIS: dict[str, dict[str, Any]] = {
    "inn-valley": {
        "label": "Inn Valley",
        "aliases": [
            "inn river",
            "inn valley",
            "inn valley aoi",
            "selected inn river aoi",
        ],
    },
    "oetztal-alps": {
        "label": "Oetztal Alps",
        "aliases": [
            "oetztal",
            "oetztal alps",
            "oetztal alps aoi",
            "selected alpine aoi",
            "oetztal alps tributary catchments",
        ],
    },
}

REQUIRED_COLUMNS_CSV = {"aoi", "month"}
SNOW_COLUMNS = ("ndsi_snow_fraction", "snow_fraction")
EFAS_COLUMNS = ("efas_anomaly_percent", "efas_anomaly", "discharge_anomaly_percent")
DEFAULT_SOURCE = "openEO platform Sentinel-2 NDSI + CDS EFAS"


@dataclass
class ImportRow:
    aoi: str
    month: str
    ndsi: float
    efas: float
    extras: dict[str, float]


def _parse_aliases(values: Iterable[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for value in values:
        if "=" not in value:
            raise SystemExit(
                f"--alias expects 'source=target' pairs, got '{value}'"
            )
        src, target = value.split("=", 1)
        out[src.strip()] = target.strip()
    return out


def _coerce_float(value: Any, *, fallback: float | None = None) -> float | None:
    if value is None or value == "":
        return fallback
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def _pick_first(row: dict[str, Any], keys: tuple[str, ...]) -> Any:
    for key in keys:
        if key in row and row[key] not in (None, ""):
            return row[key]
    return None


def _load_csv(path: Path) -> list[ImportRow]:
    with path.open("r", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames is None or not REQUIRED_COLUMNS_CSV.issubset(
            reader.fieldnames
        ):
            raise SystemExit(
                "CSV must include at least the columns: "
                + ", ".join(sorted(REQUIRED_COLUMNS_CSV))
                + f". Found: {reader.fieldnames}"
            )
        rows: list[ImportRow] = []
        for raw in reader:
            ndsi_raw = _pick_first(raw, SNOW_COLUMNS)
            efas_raw = _pick_first(raw, EFAS_COLUMNS)
            if ndsi_raw is None:
                continue
            ndsi = _coerce_float(ndsi_raw)
            if ndsi is None:
                continue
            efas = _coerce_float(efas_raw, fallback=0.0)
            extras: dict[str, float] = {}
            for key, value in raw.items():
                if key in {"aoi", "month", *SNOW_COLUMNS, *EFAS_COLUMNS}:
                    continue
                coerced = _coerce_float(value)
                if coerced is not None:
                    extras[key] = coerced
            rows.append(
                ImportRow(
                    aoi=str(raw["aoi"]).strip(),
                    month=str(raw["month"]).strip(),
                    ndsi=max(0.0, min(1.0, ndsi)),
                    efas=efas if efas is not None else 0.0,
                    extras=extras,
                )
            )
    return rows


def _load_json(path: Path) -> list[ImportRow]:
    """Accept either the canonical aoi_history.json shape or a flat list."""
    with path.open("r", encoding="utf-8") as fh:
        payload = json.load(fh)

    rows: list[ImportRow] = []

    if isinstance(payload, dict) and "histories" in payload:
        for slug, entry in payload["histories"].items():
            for point in entry.get("points", []):
                ndsi = _coerce_float(point.get("ndsi_snow_fraction"))
                efas = _coerce_float(
                    point.get("efas_anomaly_percent"),
                    fallback=0.0,
                )
                if ndsi is None:
                    continue
                rows.append(
                    ImportRow(
                        aoi=slug,
                        month=str(point["month"]),
                        ndsi=max(0.0, min(1.0, ndsi)),
                        efas=efas if efas is not None else 0.0,
                        extras={},
                    )
                )
    elif isinstance(payload, list):
        for raw in payload:
            ndsi = _coerce_float(_pick_first(raw, SNOW_COLUMNS))
            efas = _coerce_float(_pick_first(raw, EFAS_COLUMNS), fallback=0.0)
            if ndsi is None or "aoi" not in raw or "month" not in raw:
                continue
            rows.append(
                ImportRow(
                    aoi=str(raw["aoi"]).strip(),
                    month=str(raw["month"]).strip(),
                    ndsi=max(0.0, min(1.0, ndsi)),
                    efas=efas if efas is not None else 0.0,
                    extras={},
                )
            )
    else:
        raise SystemExit(
            "JSON must be either a dict with 'histories' (canonical shape) "
            "or a list of {aoi, month, ndsi_snow_fraction, ...} records."
        )

    return rows


def _build_payload(
    rows: list[ImportRow],
    source: str,
    provenance: str,
    extra_aoi_labels: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    grouped: dict[str, list[ImportRow]] = defaultdict(list)
    for row in rows:
        grouped[row.aoi].append(row)

    histories: dict[str, dict[str, Any]] = {}
    for aoi, group in grouped.items():
        group.sort(key=lambda r: r.month)
        meta = KNOWN_AOIS.get(aoi) or (extra_aoi_labels or {}).get(aoi) or {
            "label": aoi.replace("-", " ").title(),
            "aliases": [aoi],
        }
        points = [
            {
                "month": row.month,
                "ndsi_snow_fraction": round(row.ndsi, 3),
                "efas_anomaly_percent": round(row.efas, 1),
                **{k: round(v, 3) for k, v in row.extras.items()},
            }
            for row in group
        ]
        histories[aoi] = {
            "label": meta["label"],
            "aliases": list(meta.get("aliases", [aoi])),
            "source": source,
            "provenance": provenance,
            "points": points,
        }

    return {
        "_provenance": (
            "Imported from an openEO export via "
            "services/api/scripts/import_openeo_history.py."
        ),
        "histories": histories,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "input",
        type=Path,
        help="Path to the openEO export (.csv or .json).",
    )
    parser.add_argument(
        "--alias",
        action="append",
        default=[],
        help=(
            "Map a non-canonical AOI identifier in the export to a canonical "
            "slug, e.g. --alias 'oetztal_2024_v3=oetztal-alps'. May be passed "
            "multiple times."
        ),
    )
    parser.add_argument(
        "--source",
        default=DEFAULT_SOURCE,
        help="Free-text data-source description shown in the chart caption.",
    )
    parser.add_argument(
        "--provenance",
        default=(
            "openEO platform Sentinel-2 L2A NDSI + CDS Lisflood-EFAS, "
            "monthly median over AOI bbox. See python_analysis/openeo_history_format.md."
        ),
        help="Free-text provenance string shown beneath the chart.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print summary instead of writing the JSON file.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_PATH,
        help=f"Override output path (default: {OUTPUT_PATH}).",
    )
    args = parser.parse_args(argv)

    if not args.input.exists():
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        return 2

    alias_map = _parse_aliases(args.alias)

    suffix = args.input.suffix.lower()
    if suffix == ".csv":
        rows = _load_csv(args.input)
    elif suffix in {".json", ".geojson"}:
        rows = _load_json(args.input)
    else:
        print(
            f"error: unsupported extension '{suffix}'. Use .csv or .json.",
            file=sys.stderr,
        )
        return 2

    if not rows:
        print(
            "error: no usable rows found. Check the column names "
            "(see python_analysis/openeo_history_format.md).",
            file=sys.stderr,
        )
        return 2

    if alias_map:
        for row in rows:
            if row.aoi in alias_map:
                row.aoi = alias_map[row.aoi]

    payload = _build_payload(rows, source=args.source, provenance=args.provenance)

    summary_lines = []
    for slug, entry in payload["histories"].items():
        pts = entry["points"]
        first, last = pts[0]["month"], pts[-1]["month"]
        ndsi_first = sum(p["ndsi_snow_fraction"] for p in pts[: min(12, len(pts))]) / min(12, len(pts))
        ndsi_last = sum(p["ndsi_snow_fraction"] for p in pts[-min(12, len(pts)):]) / min(12, len(pts))
        summary_lines.append(
            f"  {slug}: {len(pts)} months ({first} -> {last}), "
            f"NDSI Δ = {ndsi_last - ndsi_first:+.3f}"
        )

    if args.dry_run:
        print("Dry run — would write the following payload:")
        print("\n".join(summary_lines))
        print(f"\nTarget: {args.output}")
        return 0

    args.output.write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {args.output} from {args.input}.")
    print("\n".join(summary_lines))
    print(
        "\nNext: restart the API (or wait for the auto-reload) and reload the app to see "
        "the new history series + projection line."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
