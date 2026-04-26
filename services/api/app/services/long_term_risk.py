from __future__ import annotations

import json
import logging
from datetime import UTC, datetime, timedelta
from hashlib import sha1
from math import cos, radians
from pathlib import Path
from typing import Any

from app.models.environmental_analysis import (
    AoiBounds,
    AoiHistory,
    EnvironmentalProblem,
    HistoryPoint,
    ProblemLocation,
    ProblemType,
    RiskAction,
    RiskDriver,
    RiskEvidenceMetric,
    RiskImpact,
    RiskProjection,
    RiskSignal,
    RiskTimeline,
    RiskWeights,
    Settlement,
    SettlementExposure,
    Severity,
)
from app.services.copernicus_flood_data import copernicus_flood_service


RISK_TIMELINE_CACHE_TTL = timedelta(minutes=15)
HYDROLOGY_EVIDENCE_PATH = Path(__file__).resolve().parents[1] / "data" / "hydrology_evidence.json"
SETTLEMENTS_PATH = Path(__file__).resolve().parents[1] / "data" / "alpine_settlements.json"
HISTORY_PATH = Path(__file__).resolve().parents[1] / "data" / "aoi_history.json"
SETTLEMENT_BUFFER_KM = 5.0
logger = logging.getLogger(__name__)


class LongTermRiskService:
    def __init__(self) -> None:
        self._aoi_cache: dict[str, tuple[datetime, RiskTimeline]] = {}
        self._hydrology_cache: dict[str, dict[str, Any]] | None = None
        self._settlements_cache: list[dict[str, Any]] | None = None
        self._history_cache: dict[str, dict[str, Any]] | None = None

    async def get_risk_timeline(
        self,
        water_body_id: str,
        *,
        weights: RiskWeights | None = None,
    ) -> RiskTimeline | None:
        if water_body_id != "inn-river":
            return None

        effective_weights = weights or RiskWeights()
        cache_key = self._inn_cache_key(effective_weights)
        cached = self._aoi_cache.get(cache_key)
        if cached and datetime.now(UTC) - cached[0] <= RISK_TIMELINE_CACHE_TTL:
            return cached[1]

        try:
            flood_analysis = await copernicus_flood_service.get_inn_river_analysis()
        except Exception as exc:
            logger.warning(
                "Copernicus Inn River analysis failed (%s), building fallback timeline: %r",
                type(exc).__name__,
                exc,
            )
            flood_analysis = None

        if flood_analysis is None:
            # Build a fallback timeline using mock data so the UI still works
            # when Copernicus credentials are missing.
            from app.services.mock_satellite_data import mock_satellite_service

            mock_analysis = mock_satellite_service.get_analysis_by_water_body("inn-river")
            if mock_analysis is None:
                return None

            mock_problem = mock_analysis.problems[0]
            fallback_bbox = [
                mock_problem.location.longitude - 0.2,
                mock_problem.location.latitude - 0.2,
                mock_problem.location.longitude + 0.2,
                mock_problem.location.latitude + 0.2,
            ]
            timeline = self._build_timeline(
                water_body_id="inn-river",
                water_body_name="Inn River",
                flood_problem=mock_problem,
                corridor_label="selected Inn River AOI",
                bbox=fallback_bbox,
                hydrology_evidence=self._get_hydrology_evidence(
                    water_body_id="inn-river",
                    water_body_name="Inn River",
                ),
                sentinel2_evidence=None,
                weights=effective_weights,
            )
            self._aoi_cache[cache_key] = (datetime.now(UTC), timeline)
            return timeline

        bbox_values = [
            flood_analysis.longitude - 0.2,
            flood_analysis.latitude - 0.2,
            flood_analysis.longitude + 0.2,
            flood_analysis.latitude + 0.2,
        ]
        timeline = self._build_timeline(
            water_body_id="inn-river",
            water_body_name="Inn River",
            flood_problem=flood_analysis.problems[0],
            corridor_label="selected Inn River AOI",
            bbox=bbox_values,
            hydrology_evidence=self._get_hydrology_evidence(
                water_body_id="inn-river",
                water_body_name="Inn River",
            ),
            sentinel2_evidence=await self._get_sentinel2_evidence(bbox_values),
            weights=effective_weights,
        )

        self._aoi_cache[cache_key] = (datetime.now(UTC), timeline)
        return timeline

    async def get_aoi_risk_timeline(
        self,
        *,
        label: str,
        bbox: AoiBounds,
        weights: RiskWeights | None = None,
    ) -> RiskTimeline:
        self._validate_aoi_bounds(bbox)
        bbox_values = [bbox.west, bbox.south, bbox.east, bbox.north]
        effective_weights = weights or RiskWeights()
        cache_key = self._aoi_cache_key(label, bbox_values, effective_weights)
        cached = self._aoi_cache.get(cache_key)
        if cached and datetime.now(UTC) - cached[0] <= RISK_TIMELINE_CACHE_TTL:
            return cached[1]

        water_body_id = f"aoi-{cache_key[:10]}"
        try:
            flood_analysis = await copernicus_flood_service.get_analysis_for_bbox(
                bbox=bbox_values,
                label=label,
                water_body_id=water_body_id,
            )
            sentinel2_evidence = await self._get_sentinel2_evidence(bbox_values)
        except Exception as exc:
            logger.warning(
                "Copernicus AOI analysis failed (%s), building fallback timeline: %r",
                type(exc).__name__,
                exc,
            )
            # Build a minimal fallback problem for the AOI
            flood_analysis = EnvironmentalProblem(
                id=f"{water_body_id}-flood-001",
                type=ProblemType.flood,
                severity=Severity.medium,
                location=ProblemLocation(
                    latitude=(bbox.south + bbox.north) / 2,
                    longitude=(bbox.west + bbox.east) / 2,
                    radius_km=10.0,
                ),
                detected_at=datetime.now(UTC).isoformat().replace("+00:00", "Z"),
                source="Mock fallback (Copernicus unavailable)",
                description="AOI screening fallback. No live Copernicus credentials configured.",
            )
            sentinel2_evidence = None

        timeline = self._build_timeline(
            water_body_id=water_body_id,
            water_body_name=label,
            flood_problem=flood_analysis.problems[0] if hasattr(flood_analysis, "problems") else flood_analysis,
            corridor_label="selected Alpine AOI",
            bbox=bbox_values,
            hydrology_evidence=self._get_hydrology_evidence(
                water_body_id=water_body_id,
                water_body_name=label,
            ),
            sentinel2_evidence=sentinel2_evidence,
            weights=effective_weights,
        )
        self._aoi_cache[cache_key] = (datetime.now(UTC), timeline)
        return timeline

    def _build_timeline(
        self,
        *,
        water_body_id: str,
        water_body_name: str,
        flood_problem: EnvironmentalProblem,
        corridor_label: str,
        bbox: list[float],
        hydrology_evidence: dict[str, Any] | None,
        sentinel2_evidence: dict[str, float | str] | None,
        weights: RiskWeights | None = None,
    ) -> RiskTimeline:
        effective_weights = weights or RiskWeights()
        has_s2 = sentinel2_evidence is not None
        ndwi_water_fraction = self._evidence_value(sentinel2_evidence, "ndwi_water_fraction")
        low_vegetation_fraction = self._evidence_value(
            sentinel2_evidence, "low_vegetation_fraction"
        )
        snow_fraction = self._evidence_value(sentinel2_evidence, "snow_fraction")
        mean_ndvi = self._evidence_value(sentinel2_evidence, "mean_ndvi")
        valid_pixel_fraction = self._evidence_value(
            sentinel2_evidence, "valid_pixel_fraction"
        )
        discharge_anomaly_fraction = self._hydrology_anomaly_fraction(hydrology_evidence)

        # Apply user-supplied weight knobs to each evidence channel. Weighted
        # values stay clamped to [0, 1] so projection score thresholds remain
        # meaningful when a weight is >1.
        weighted_snow = self._clamp_unit(snow_fraction * effective_weights.snow)
        weighted_ndwi = self._clamp_unit(ndwi_water_fraction * effective_weights.surface_water)
        weighted_low_veg = self._clamp_unit(
            low_vegetation_fraction * effective_weights.vegetation
        )
        weighted_anomaly = self._clamp_unit(
            discharge_anomaly_fraction * effective_weights.hydrology
        )

        confidence = self._confidence_label(has_s2, valid_pixel_fraction)
        observed_flood_pressure = self._screening_signal_severity(flood_problem.severity)
        flood_risk_10 = self._projected_flood_risk(
            observed_flood_pressure, weighted_ndwi, weighted_anomaly, 10
        )
        flood_risk_20 = self._projected_flood_risk(
            observed_flood_pressure, weighted_ndwi, weighted_anomaly, 20
        )
        flood_risk_50 = self._projected_flood_risk(
            observed_flood_pressure, weighted_ndwi, weighted_anomaly, 50
        )
        landslide_risk_today = self._landslide_risk(weighted_low_veg, weighted_snow, 0)
        landslide_risk_10 = self._landslide_risk(weighted_low_veg, weighted_snow, 10)
        landslide_risk_20 = self._landslide_risk(weighted_low_veg, weighted_snow, 20)
        landslide_risk_50 = self._landslide_risk(weighted_low_veg, weighted_snow, 50)
        discharge_10 = (
            6.0
            + (weighted_snow * 10.0)
            + (weighted_ndwi * 12.0)
            + (weighted_anomaly * 25.0)
        )
        discharge_20 = discharge_10 + 7.0 + (weighted_low_veg * 5.0)
        discharge_50 = discharge_20 + 10.0 + (weighted_snow * 8.0)
        area_10 = 4.0 + (weighted_ndwi * 10.0)
        area_20 = area_10 + 6.0 + (weighted_low_veg * 4.0)
        area_50 = area_20 + 8.0 + (weighted_snow * 6.0)
        current_signal_severity = observed_flood_pressure
        evidence_metrics = self._build_evidence_metrics(
            flood_problem=flood_problem,
            ndwi_water_fraction=ndwi_water_fraction,
            low_vegetation_fraction=low_vegetation_fraction,
            snow_fraction=snow_fraction,
            mean_ndvi=mean_ndvi,
            valid_pixel_fraction=valid_pixel_fraction,
            has_sentinel2=has_s2,
            hydrology_evidence=hydrology_evidence,
        )
        settlement_exposure = self._compute_settlement_exposure(bbox)
        current_summary = flood_problem.description
        source = flood_problem.source
        if has_s2:
            source = f"{source} / Copernicus Sentinel-2 L2A"
            current_summary = (
                f"{current_summary} Sentinel-2 L2A adds optical context: "
                f"NDWI water-like pixels {ndwi_water_fraction * 100:.1f}%, "
                f"low-vegetation pixels {low_vegetation_fraction * 100:.1f}%, "
                f"snow-proxy pixels {snow_fraction * 100:.1f}% "
                f"over {valid_pixel_fraction * 100:.0f}% valid cloud-screened pixels."
            )

        return RiskTimeline(
            water_body_id=water_body_id,
            water_body_name=water_body_name,
            generated_at=datetime.now(UTC).isoformat().replace("+00:00", "Z"),
            analysis_period_days=30,
            aoi_area_km2=round(self._bbox_area_km2(bbox), 1),
            confidence_label="Medium-high" if has_s2 and valid_pixel_fraction >= 0.5 else "Medium",
            confidence=confidence,
            methodology_note=(
                "This is an explainable screening workflow, not an official warning product. "
                "Observed Copernicus indicators are combined with transparent scenario multipliers; "
                "operational use needs discharge, DEM/slope, and exposure calibration."
            ),
            observed_data_sources=[
                "Copernicus Sentinel-1 GRD SAR water-like backscatter",
                *(
                    [
                        "Copernicus Sentinel-2 L2A NDWI optical water proxy",
                        "Copernicus Sentinel-2 L2A NDVI vegetation proxy",
                        "Copernicus Sentinel-2 L2A NDSI-style snow proxy",
                    ]
                    if has_s2
                    else []
                ),
                *(
                    ["CDS Lisflood-EFAS seasonal river discharge context"]
                    if hydrology_evidence
                    else []
                ),
            ],
            scenario_assumptions=[
                "Climate-pressure multipliers approximate stronger rainfall and earlier snowmelt.",
                (
                    "Runoff and inundation pressure are evidence-scaled indices informed by cached EFAS discharge context, "
                    "not local-gauge-calibrated forecasts."
                    if hydrology_evidence
                    else "Runoff and inundation pressure are evidence-scaled indices, not calibrated discharge forecasts."
                ),
                "Landslide susceptibility is inferred from vegetation/snow proxies until slope and geology layers are added.",
            ],
            missing_operational_layers=[
                (
                    "Automated EFAS/Lisflood refresh and local gauge calibration"
                    if hydrology_evidence
                    else "EFAS/Lisflood discharge or local gauge calibration"
                ),
                "Copernicus DEM-derived slope/aspect and local hazard zones",
                "Buildings, roads, population, tourism, agriculture, and insured-value exposure layers",
            ],
            current_signal=RiskSignal(
                label="Current screening signal",
                value=f"{current_signal_severity.value.upper()} SIGNAL",
                severity=current_signal_severity,
                source=source,
                summary=current_summary,
            ),
            drivers=[
                RiskDriver(
                    id="surface-water",
                    label="Multi-sensor surface-water signal",
                    status="Active",
                    trend="Increasing SAR signal",
                    detail=(
                        f"Sentinel-1 SAR detected water-like backscatter across the {corridor_label} "
                        f"during the last 30 days. Sentinel-2 NDWI independently flags "
                        f"{ndwi_water_fraction * 100:.1f}% optical water-like pixels where cloud-screened data is valid."
                    ),
                    source="Copernicus Sentinel-1 GRD / Sentinel-2 L2A",
                ),
                RiskDriver(
                    id="snowmelt",
                    label="Snow and meltwater proxy",
                    status="Observed proxy" if has_s2 else "Scenario driver",
                    trend=self._snow_trend_label(snow_fraction),
                    detail=(
                        f"Sentinel-2 NDSI-style screening estimates {snow_fraction * 100:.1f}% snow-like pixels. "
                        "This does not forecast melt timing alone, but it indicates how much snow storage can feed runoff pulses."
                    ),
                    source="Copernicus Sentinel-2 L2A NDSI proxy",
                ),
                RiskDriver(
                    id="vegetation-buffering",
                    label="Vegetation runoff buffering",
                    status="Observed proxy" if has_s2 else "Scenario driver",
                    trend=self._vegetation_trend_label(low_vegetation_fraction),
                    detail=(
                        f"Sentinel-2 NDVI estimates mean vegetation index {mean_ndvi:.2f}, with "
                        f"{low_vegetation_fraction * 100:.1f}% low-vegetation pixels. Lower vegetation buffering "
                        "can increase runoff speed and slope susceptibility."
                    ),
                    source="Copernicus Sentinel-2 L2A NDVI",
                ),
                RiskDriver(
                    id="hydrology-discharge",
                    label="Seasonal discharge context",
                    status="Cached forecast context" if hydrology_evidence else "Not connected",
                    trend=self._hydrology_trend_label(hydrology_evidence),
                    detail=self._hydrology_driver_detail(hydrology_evidence),
                    source=(
                        str(hydrology_evidence["source"])
                        if hydrology_evidence
                        else "CDS Lisflood-EFAS placeholder"
                    ),
                ),
                RiskDriver(
                    id="slope-instability",
                    label="Slope saturation and instability",
                    status="Watch",
                    trend="Higher landslide susceptibility",
                    detail=(
                        "Repeated flood pulses and saturated valley slopes can raise debris-flow and landslide "
                        "susceptibility near infrastructure corridors. This remains a placeholder until DEM slope "
                        "and local hazard-zone layers are added."
                    ),
                    source="DEM / local hazard layer placeholder",
                ),
            ],
            projections=[
                RiskProjection(
                    horizon_years=0,
                    label="Today",
                    flood_risk=observed_flood_pressure,
                    landslide_risk=landslide_risk_today,
                    discharge_change_percent=0.0,
                    flood_prone_area_change_percent=0.0,
                    summary="Observed screening pressure from Sentinel-1 SAR plus Sentinel-2 optical water, snow, and vegetation proxies. This is not an official alert level.",
                ),
                RiskProjection(
                    horizon_years=10,
                    label="10 years",
                    flood_risk=flood_risk_10,
                    landslide_risk=landslide_risk_10,
                    discharge_change_percent=round(discharge_10, 1),
                    flood_prone_area_change_percent=round(area_10, 1),
                    summary="Near-term scenario pressure from current Copernicus evidence. Critical escalation is withheld unless multiple strong proxies align.",
                ),
                RiskProjection(
                    horizon_years=20,
                    label="20 years",
                    flood_risk=flood_risk_20,
                    landslide_risk=landslide_risk_20,
                    discharge_change_percent=round(discharge_20, 1),
                    flood_prone_area_change_percent=round(area_20, 1),
                    summary="Medium-horizon stress test. Snow storage and weaker vegetation buffering raise pressure, but values remain screening classes.",
                ),
                RiskProjection(
                    horizon_years=50,
                    label="50 years",
                    flood_risk=flood_risk_50,
                    landslide_risk=landslide_risk_50,
                    discharge_change_percent=round(discharge_50, 1),
                    flood_prone_area_change_percent=round(area_50, 1),
                    summary="Long-horizon stress test derived from current Copernicus evidence plus climate-pressure assumptions; use as prioritization guidance, not a forecast.",
                ),
            ],
            impacts=self._build_impacts(settlement_exposure),
            actions=[
                RiskAction(
                    priority="Immediate",
                    title="Ground-truth the SAR water-like signal",
                    timeline="Today",
                    expected_effect="Separates active inundation from wet snow, saturated ground, radar shadow, or other smooth-surface SAR responses.",
                    estimated_cost="Operational monitoring",
                ),
                RiskAction(
                    priority="Near-term",
                    title="Calibrate with EFAS/Lisflood discharge and local gauges",
                    timeline="1-2 weeks",
                    expected_effect="Converts the current evidence index into river-specific discharge thresholds and return-period context.",
                    estimated_cost="Low once CDS access is configured",
                ),
                RiskAction(
                    priority="Planning",
                    title="Add DEM, slope, land-cover, and exposure overlays",
                    timeline="3-12 months",
                    expected_effect="Turns the AOI screening into a decision map for slope inspections, retention planning, and infrastructure prioritization.",
                    estimated_cost="Medium",
                ),
            ],
            evidence=evidence_metrics,
            settlement_exposure=settlement_exposure,
            weights=effective_weights,
        )

    def _build_impacts(
        self,
        settlement_exposure: SettlementExposure | None,
    ) -> list[RiskImpact]:
        if settlement_exposure and settlement_exposure.total_settlements > 0:
            top_names = ", ".join(
                s.name for s in settlement_exposure.settlements[:5]
            )
            extra = (
                f" (+{settlement_exposure.total_settlements - 5} more)"
                if settlement_exposure.total_settlements > 5
                else ""
            )
            population_label = (
                f"~{settlement_exposure.total_population:,} residents"
            ).replace(",", ".")
            exposure_impact = RiskImpact(
                category="Population exposure",
                metric=(
                    f"Settlements within {settlement_exposure.buffer_km:.0f} km of AOI"
                ),
                value=(
                    f"{settlement_exposure.total_settlements} settlements, "
                    f"{population_label}"
                ),
                detail=(
                    f"{settlement_exposure.inside_aoi} inside the AOI, "
                    f"{settlement_exposure.within_buffer} within the {settlement_exposure.buffer_km:.0f} km buffer. "
                    f"Top exposure: {top_names}{extra}. "
                    "Source: curated Statistik Austria municipality cache; replace with live cadastral / GHSL grid for production use."
                ),
            )
        else:
            exposure_impact = RiskImpact(
                category="Exposure gap",
                metric="Building and population layer",
                value="Not connected",
                detail=(
                    "No curated Alpine settlements matched this AOI. Plug in a live cadastral, "
                    "building-footprint, or GHSL population grid for full coverage."
                ),
            )

        return [
            exposure_impact,
            RiskImpact(
                category="Infrastructure",
                metric="Road and rail overlay",
                value="Required next",
                detail=(
                    "Combine the AOI with OpenStreetMap or official transport layers to identify "
                    "bridges, roads, and rail corridors intersecting screened water or slope-risk zones."
                ),
            ),
            RiskImpact(
                category="Hazard model gap",
                metric="DEM and slope layer",
                value="Pending",
                detail=(
                    "Landslide interpretation needs slope, aspect, geology, and rainfall/saturation layers. "
                    "Current landslide risk is only an evidence-scaled proxy."
                ),
            ),
            RiskImpact(
                category="Economic use",
                metric="Tourism and agriculture exposure",
                value="Pending",
                detail=(
                    "Tourism facilities, farms, and access roads should be layered on top of the AOI "
                    "to translate hazard screening into economic exposure."
                ),
            ),
        ]

    def _inn_cache_key(self, weights: RiskWeights) -> str:
        weights_signature = self._weights_signature(weights)
        return sha1(f"inn-river:{weights_signature}".encode("utf-8")).hexdigest()

    def _weights_signature(self, weights: RiskWeights) -> str:
        return (
            f"snow={weights.snow:.3f};water={weights.surface_water:.3f};"
            f"veg={weights.vegetation:.3f};hyd={weights.hydrology:.3f}"
        )

    async def _get_sentinel2_evidence(
        self,
        bbox: list[float],
    ) -> dict[str, float | str] | None:
        try:
            return await copernicus_flood_service.get_sentinel2_evidence_for_bbox(
                bbox=bbox
            )
        except Exception:
            return None

    def _evidence_value(
        self,
        evidence: dict[str, float | str] | None,
        key: str,
    ) -> float:
        if evidence is None:
            return 0.0
        value = evidence.get(key, 0.0)
        return float(value) if isinstance(value, int | float) else 0.0

    def _confidence_label(
        self,
        has_sentinel2: bool,
        valid_pixel_fraction: float,
    ) -> str:
        if not has_sentinel2:
            return "Medium - current flood signal is live Copernicus Sentinel-1 data; Sentinel-2 optical confirmation was unavailable, and long-term values remain scenario-based."
        if valid_pixel_fraction >= 0.5:
            return "Medium-high - current screening combines live Copernicus Sentinel-1 SAR with cloud-screened Sentinel-2 optical water, snow, and vegetation indicators; long-term values remain scenario projections pending EFAS/Lisflood calibration."
        return "Medium - Sentinel-1 SAR is live and Sentinel-2 indicators were computed, but cloud-screened optical coverage is limited; long-term values remain scenario projections pending EFAS/Lisflood calibration."

    def _build_evidence_metrics(
        self,
        *,
        flood_problem: EnvironmentalProblem,
        ndwi_water_fraction: float,
        low_vegetation_fraction: float,
        snow_fraction: float,
        mean_ndvi: float,
        valid_pixel_fraction: float,
        has_sentinel2: bool,
        hydrology_evidence: dict[str, Any] | None,
    ) -> list[RiskEvidenceMetric]:
        sar_fraction = self._extract_percent_fraction(flood_problem.description)
        metrics = [
            RiskEvidenceMetric(
                label="SAR water-like signal",
                value=round(sar_fraction * 100, 1),
                unit="%",
                fraction=sar_fraction,
                interpretation="Radar pixels matching water-like backscatter; can include wet snow, saturated ground, or radar shadow.",
                source="Copernicus Sentinel-1 GRD",
            ),
        ]

        if has_sentinel2:
            metrics.extend(
                [
                    RiskEvidenceMetric(
                        label="Optical water proxy",
                        value=round(ndwi_water_fraction * 100, 1),
                        unit="%",
                        fraction=ndwi_water_fraction,
                        interpretation="NDWI water-like pixels in cloud-screened Sentinel-2 imagery.",
                        source="Copernicus Sentinel-2 L2A NDWI",
                    ),
                    RiskEvidenceMetric(
                        label="Snow proxy",
                        value=round(snow_fraction * 100, 1),
                        unit="%",
                        fraction=snow_fraction,
                        interpretation="NDSI-style snow-like pixels that may contribute to meltwater runoff.",
                        source="Copernicus Sentinel-2 L2A NDSI proxy",
                    ),
                    RiskEvidenceMetric(
                        label="Low vegetation proxy",
                        value=round(low_vegetation_fraction * 100, 1),
                        unit="%",
                        fraction=low_vegetation_fraction,
                        interpretation="Low-NDVI pixels where runoff buffering and slope stability may be weaker.",
                        source="Copernicus Sentinel-2 L2A NDVI",
                    ),
                    RiskEvidenceMetric(
                        label="Mean NDVI",
                        value=round(mean_ndvi, 2),
                        unit="",
                        fraction=max(0.0, min(1.0, (mean_ndvi + 1) / 2)),
                        interpretation="Average vegetation index across valid Sentinel-2 pixels.",
                        source="Copernicus Sentinel-2 L2A NDVI",
                    ),
                    RiskEvidenceMetric(
                        label="Valid optical coverage",
                        value=round(valid_pixel_fraction * 100, 1),
                        unit="%",
                        fraction=valid_pixel_fraction,
                        interpretation="Share of AOI pixels remaining after Sentinel-2 cloud and invalid-pixel masking.",
                        source="Copernicus Sentinel-2 L2A Scene Classification",
                    ),
                ]
            )

        if hydrology_evidence:
            anomaly_percent = float(hydrology_evidence["discharge_anomaly_percent"])
            metrics.append(
                RiskEvidenceMetric(
                    label="EFAS discharge anomaly",
                    value=round(anomaly_percent, 1),
                    unit="%",
                    fraction=max(0.0, min(1.0, anomaly_percent / 40.0)),
                    interpretation=(
                        f"{hydrology_evidence['return_period_signal']} for the "
                        f"{hydrology_evidence['analysis_month'].lower()} "
                        f"over {hydrology_evidence['forecast_horizon_months']} months. "
                        "This is cached hydrology context, not a live warning."
                    ),
                    source=str(hydrology_evidence["source"]),
                )
            )

        return metrics

    def _get_hydrology_evidence(
        self,
        *,
        water_body_id: str,
        water_body_name: str,
    ) -> dict[str, Any] | None:
        evidence_by_id = self._load_hydrology_cache()
        if water_body_id in evidence_by_id:
            return evidence_by_id[water_body_id]

        normalized_name = water_body_name.casefold()
        for evidence in evidence_by_id.values():
            matched_labels = evidence.get("matched_labels", [])
            if any(str(label).casefold() == normalized_name for label in matched_labels):
                return evidence
        return None

    def _load_hydrology_cache(self) -> dict[str, dict[str, Any]]:
        if self._hydrology_cache is not None:
            return self._hydrology_cache

        try:
            with HYDROLOGY_EVIDENCE_PATH.open("r", encoding="utf-8") as file:
                data = json.load(file)
        except FileNotFoundError:
            data = {}

        self._hydrology_cache = {
            str(key): value
            for key, value in data.items()
            if isinstance(value, dict)
        }
        return self._hydrology_cache

    def _hydrology_anomaly_fraction(
        self,
        hydrology_evidence: dict[str, Any] | None,
    ) -> float:
        if not hydrology_evidence:
            return 0.0
        anomaly_percent = float(hydrology_evidence.get("discharge_anomaly_percent", 0.0))
        return max(0.0, min(1.0, anomaly_percent / 40.0))

    def _hydrology_trend_label(self, hydrology_evidence: dict[str, Any] | None) -> str:
        if not hydrology_evidence:
            return "Awaiting EFAS cache"
        anomaly_percent = float(hydrology_evidence["discharge_anomaly_percent"])
        if anomaly_percent >= 20:
            return "Strong above-normal discharge"
        if anomaly_percent >= 10:
            return "Above-normal discharge"
        if anomaly_percent > 0:
            return "Slightly elevated discharge"
        return "Near-normal discharge"

    def _hydrology_driver_detail(
        self,
        hydrology_evidence: dict[str, Any] | None,
    ) -> str:
        if not hydrology_evidence:
            return (
                "CDS Lisflood-EFAS discharge context is the next calibration layer. "
                "Without it, scenario pressure is based on satellite proxies only."
            )
        return (
            f"Cached Lisflood-EFAS context indicates "
            f"{float(hydrology_evidence['discharge_anomaly_percent']):.1f}% "
            f"above-normal seasonal discharge for {hydrology_evidence['label']} "
            f"({hydrology_evidence['analysis_month']}). "
            f"{hydrology_evidence['provenance']}"
        )

    def _extract_percent_fraction(self, text: str) -> float:
        marker = "% of the sampled area"
        if marker not in text:
            return 0.0
        prefix = text.split(marker, 1)[0]
        value_text = prefix.rsplit("(", 1)[-1].strip()
        try:
            return max(0.0, min(1.0, float(value_text) / 100))
        except ValueError:
            return 0.0

    def _screening_signal_severity(self, severity: Severity) -> Severity:
        if severity == Severity.critical:
            return Severity.high
        return severity

    def _snow_trend_label(self, snow_fraction: float) -> str:
        if snow_fraction >= 0.25:
            return "High snow-storage signal"
        if snow_fraction >= 0.08:
            return "Moderate snow-storage signal"
        return "Low current snow signal"

    def _vegetation_trend_label(self, low_vegetation_fraction: float) -> str:
        if low_vegetation_fraction >= 0.55:
            return "Weak vegetation buffering"
        if low_vegetation_fraction >= 0.30:
            return "Mixed vegetation buffering"
        return "Stronger vegetation buffering"

    def _projected_flood_risk(
        self,
        current: Severity,
        ndwi_water_fraction: float,
        discharge_anomaly_fraction: float,
        horizon_years: int,
    ) -> Severity:
        score = min(self._severity_score(current), 2)
        if ndwi_water_fraction >= 0.25:
            score += 1
        elif ndwi_water_fraction >= 0.10 and horizon_years >= 20:
            score += 1
        if discharge_anomaly_fraction >= 0.5:
            score += 1
        elif discharge_anomaly_fraction >= 0.25 and horizon_years >= 20:
            score += 1
        if horizon_years >= 50:
            score += 1
        elif horizon_years >= 20 and score < 2:
            score += 1
        return self._scenario_severity_from_score(score)

    def _landslide_risk(
        self,
        low_vegetation_fraction: float,
        snow_fraction: float,
        horizon_years: int,
    ) -> Severity:
        score = 0
        if low_vegetation_fraction >= 0.35:
            score += 1
        if low_vegetation_fraction >= 0.55 or snow_fraction >= 0.20:
            score += 1
        if horizon_years >= 20:
            score += 1
        if horizon_years >= 50:
            score += 1
        return self._scenario_severity_from_score(score)

    def _severity_score(self, severity: Severity) -> int:
        return {
            Severity.low: 0,
            Severity.medium: 1,
            Severity.high: 2,
            Severity.critical: 3,
        }[severity]

    def _severity_from_score(self, score: int) -> Severity:
        if score >= 3:
            return Severity.critical
        if score == 2:
            return Severity.high
        if score == 1:
            return Severity.medium
        return Severity.low

    def _scenario_severity_from_score(self, score: int) -> Severity:
        if score >= 4:
            return Severity.critical
        if score >= 2:
            return Severity.high
        if score == 1:
            return Severity.medium
        return Severity.low

    def _validate_aoi_bounds(self, bbox: AoiBounds) -> None:
        if bbox.west >= bbox.east or bbox.south >= bbox.north:
            raise ValueError("AOI bbox must be ordered as west < east and south < north")

        if bbox.west < -180 or bbox.east > 180 or bbox.south < -90 or bbox.north > 90:
            raise ValueError("AOI bbox is outside valid WGS84 bounds")

        if (bbox.east - bbox.west) > 1.2 or (bbox.north - bbox.south) > 1.2:
            raise ValueError("AOI bbox is too large for interactive screening; keep it below 1.2 degrees per side")

    def _aoi_cache_key(
        self,
        label: str,
        bbox: list[float],
        weights: RiskWeights,
    ) -> str:
        rounded = ",".join(f"{value:.4f}" for value in bbox)
        weights_signature = self._weights_signature(weights)
        return sha1(
            f"{label}:{rounded}:{weights_signature}".encode("utf-8")
        ).hexdigest()

    def _bbox_area_km2(self, bbox: list[float]) -> float:
        min_lon, min_lat, max_lon, max_lat = bbox
        lat_km = (max_lat - min_lat) * 111.32
        center_lat = (min_lat + max_lat) / 2
        lon_km = (max_lon - min_lon) * 111.32 * cos(radians(center_lat))
        return abs(lat_km * lon_km)

    def _clamp_unit(self, value: float) -> float:
        if value < 0.0:
            return 0.0
        if value > 1.0:
            return 1.0
        return value

    def _compute_settlement_exposure(
        self,
        bbox: list[float],
        buffer_km: float = SETTLEMENT_BUFFER_KM,
    ) -> SettlementExposure | None:
        settlements = self._load_settlements()
        if not settlements:
            return None

        min_lon, min_lat, max_lon, max_lat = bbox
        center_lat = (min_lat + max_lat) / 2
        center_lon = (min_lon + max_lon) / 2

        # Convert the buffer distance to lat/lon padding for a quick
        # rectangular pre-filter, then refine with a great-circle distance to
        # the AOI centroid.
        lat_pad = buffer_km / 111.32
        lon_pad = buffer_km / (111.32 * max(cos(radians(center_lat)), 0.05))

        matched: list[Settlement] = []
        inside_aoi = 0
        within_buffer = 0
        for entry in settlements:
            lat = float(entry["lat"])
            lon = float(entry["lon"])
            if lat < min_lat - lat_pad or lat > max_lat + lat_pad:
                continue
            if lon < min_lon - lon_pad or lon > max_lon + lon_pad:
                continue

            is_inside = min_lat <= lat <= max_lat and min_lon <= lon <= max_lon
            distance_km = self._haversine_km(center_lat, center_lon, lat, lon)
            if not is_inside and distance_km > buffer_km + self._aoi_half_diagonal_km(bbox):
                continue

            matched.append(
                Settlement(
                    name=str(entry["name"]),
                    latitude=lat,
                    longitude=lon,
                    population=int(entry["population"]),
                    kind=str(entry["kind"]),
                    region=str(entry["region"]),
                    distance_km=round(distance_km, 1),
                )
            )
            if is_inside:
                inside_aoi += 1
            else:
                within_buffer += 1

        if not matched:
            return None

        matched.sort(key=lambda s: (-s.population, s.distance_km))
        total_population = sum(s.population for s in matched)
        return SettlementExposure(
            total_settlements=len(matched),
            total_population=total_population,
            inside_aoi=inside_aoi,
            within_buffer=within_buffer,
            buffer_km=buffer_km,
            settlements=matched,
        )

    def _aoi_half_diagonal_km(self, bbox: list[float]) -> float:
        min_lon, min_lat, max_lon, max_lat = bbox
        center_lat = (min_lat + max_lat) / 2
        lat_km = (max_lat - min_lat) / 2 * 111.32
        lon_km = (max_lon - min_lon) / 2 * 111.32 * cos(radians(center_lat))
        return (lat_km**2 + lon_km**2) ** 0.5

    def _haversine_km(
        self,
        lat1: float,
        lon1: float,
        lat2: float,
        lon2: float,
    ) -> float:
        from math import asin, sin, sqrt

        r_km = 6371.0088
        phi1 = radians(lat1)
        phi2 = radians(lat2)
        d_phi = radians(lat2 - lat1)
        d_lambda = radians(lon2 - lon1)
        a = sin(d_phi / 2) ** 2 + cos(phi1) * cos(phi2) * sin(d_lambda / 2) ** 2
        return 2 * r_km * asin(min(1.0, sqrt(a)))

    def _load_settlements(self) -> list[dict[str, Any]]:
        if self._settlements_cache is not None:
            return self._settlements_cache

        try:
            with SETTLEMENTS_PATH.open("r", encoding="utf-8") as file:
                data = json.load(file)
        except FileNotFoundError:
            self._settlements_cache = []
            return self._settlements_cache

        settlements = data.get("settlements") if isinstance(data, dict) else None
        self._settlements_cache = list(settlements) if isinstance(settlements, list) else []
        return self._settlements_cache

    def get_aoi_history(self, label: str) -> AoiHistory | None:
        histories = self._load_histories()
        if not histories:
            return None

        normalized = self._normalize_history_key(label)

        for entry in histories.values():
            if not isinstance(entry, dict):
                continue
            entry_label = self._normalize_history_key(str(entry.get("label", "")))
            if entry_label == normalized:
                return self._history_from_entry(entry)
            aliases = entry.get("aliases") or []
            for alias in aliases:
                if self._normalize_history_key(str(alias)) == normalized:
                    return self._history_from_entry(entry)
            # Substring fallback so e.g. "aoi-abc123" labels carrying
            # "Inn River corridor" still match.
            if entry_label and entry_label in normalized:
                return self._history_from_entry(entry)

        return None

    def _history_from_entry(self, entry: dict[str, Any]) -> AoiHistory:
        points = [
            HistoryPoint(
                month=str(point["month"]),
                ndsi_snow_fraction=float(point["ndsi_snow_fraction"]),
                efas_anomaly_percent=float(point["efas_anomaly_percent"]),
            )
            for point in entry.get("points", [])
            if isinstance(point, dict)
        ]
        return AoiHistory(
            label=str(entry.get("label", "")),
            source=str(entry.get("source", "")),
            provenance=str(entry.get("provenance", "")),
            points=points,
        )

    def _normalize_history_key(self, value: str) -> str:
        return (
            value.strip()
            .lower()
            .replace("ö", "oe")
            .replace("ü", "ue")
            .replace("ä", "ae")
            .replace("ß", "ss")
        )

    def _load_histories(self) -> dict[str, dict[str, Any]]:
        if self._history_cache is not None:
            return self._history_cache

        try:
            with HISTORY_PATH.open("r", encoding="utf-8") as file:
                data = json.load(file)
        except FileNotFoundError:
            self._history_cache = {}
            return self._history_cache

        histories = data.get("histories") if isinstance(data, dict) else None
        self._history_cache = dict(histories) if isinstance(histories, dict) else {}
        return self._history_cache


long_term_risk_service = LongTermRiskService()
