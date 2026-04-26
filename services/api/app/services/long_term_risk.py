from __future__ import annotations

from datetime import UTC, datetime, timedelta
from hashlib import sha1

from app.models.environmental_analysis import (
    AoiBounds,
    EnvironmentalProblem,
    RiskAction,
    RiskDriver,
    RiskEvidenceMetric,
    RiskImpact,
    RiskProjection,
    RiskSignal,
    RiskTimeline,
    Severity,
)
from app.services.copernicus_flood_data import copernicus_flood_service


RISK_TIMELINE_CACHE_TTL = timedelta(minutes=15)


class LongTermRiskService:
    def __init__(self) -> None:
        self._inn_cache: RiskTimeline | None = None
        self._inn_cached_at: datetime | None = None
        self._aoi_cache: dict[str, tuple[datetime, RiskTimeline]] = {}

    async def get_risk_timeline(self, water_body_id: str) -> RiskTimeline | None:
        if water_body_id != "inn-river":
            return None

        cached = self._get_cached_inn_timeline()
        if cached:
            return cached

        flood_analysis = await copernicus_flood_service.get_inn_river_analysis()
        timeline = self._build_timeline(
            water_body_id="inn-river",
            water_body_name="Inn River",
            flood_problem=flood_analysis.problems[0],
            corridor_label="selected Inn River AOI",
            sentinel2_evidence=await self._get_sentinel2_evidence(
                [
                    flood_analysis.longitude - 0.2,
                    flood_analysis.latitude - 0.2,
                    flood_analysis.longitude + 0.2,
                    flood_analysis.latitude + 0.2,
                ]
            ),
        )

        self._inn_cache = timeline
        self._inn_cached_at = datetime.now(UTC)
        return timeline

    async def get_aoi_risk_timeline(
        self,
        *,
        label: str,
        bbox: AoiBounds,
    ) -> RiskTimeline:
        self._validate_aoi_bounds(bbox)
        bbox_values = [bbox.west, bbox.south, bbox.east, bbox.north]
        cache_key = self._aoi_cache_key(label, bbox_values)
        cached = self._aoi_cache.get(cache_key)
        if cached and datetime.now(UTC) - cached[0] <= RISK_TIMELINE_CACHE_TTL:
            return cached[1]

        water_body_id = f"aoi-{cache_key[:10]}"
        flood_analysis = await copernicus_flood_service.get_analysis_for_bbox(
            bbox=bbox_values,
            label=label,
            water_body_id=water_body_id,
        )
        sentinel2_evidence = await self._get_sentinel2_evidence(bbox_values)
        timeline = self._build_timeline(
            water_body_id=water_body_id,
            water_body_name=label,
            flood_problem=flood_analysis.problems[0],
            corridor_label="selected Alpine AOI",
            sentinel2_evidence=sentinel2_evidence,
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
        sentinel2_evidence: dict[str, float | str] | None,
    ) -> RiskTimeline:
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
        confidence = self._confidence_label(has_s2, valid_pixel_fraction)
        flood_risk_10 = self._projected_flood_risk(flood_problem.severity, ndwi_water_fraction, 10)
        flood_risk_20 = self._projected_flood_risk(flood_problem.severity, ndwi_water_fraction, 20)
        flood_risk_50 = self._projected_flood_risk(flood_problem.severity, ndwi_water_fraction, 50)
        landslide_risk_today = self._landslide_risk(low_vegetation_fraction, snow_fraction, 0)
        landslide_risk_10 = self._landslide_risk(low_vegetation_fraction, snow_fraction, 10)
        landslide_risk_20 = self._landslide_risk(low_vegetation_fraction, snow_fraction, 20)
        landslide_risk_50 = self._landslide_risk(low_vegetation_fraction, snow_fraction, 50)
        discharge_10 = 6.0 + (snow_fraction * 10.0) + (ndwi_water_fraction * 12.0)
        discharge_20 = discharge_10 + 7.0 + (low_vegetation_fraction * 5.0)
        discharge_50 = discharge_20 + 10.0 + (snow_fraction * 8.0)
        area_10 = 4.0 + (ndwi_water_fraction * 10.0)
        area_20 = area_10 + 6.0 + (low_vegetation_fraction * 4.0)
        area_50 = area_20 + 8.0 + (snow_fraction * 6.0)
        current_signal_severity = self._screening_signal_severity(flood_problem.severity)
        evidence_metrics = self._build_evidence_metrics(
            flood_problem=flood_problem,
            ndwi_water_fraction=ndwi_water_fraction,
            low_vegetation_fraction=low_vegetation_fraction,
            snow_fraction=snow_fraction,
            mean_ndvi=mean_ndvi,
            valid_pixel_fraction=valid_pixel_fraction,
            has_sentinel2=has_s2,
        )
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
            confidence=confidence,
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
                    flood_risk=flood_problem.severity,
                    landslide_risk=landslide_risk_today,
                    discharge_change_percent=0.0,
                    flood_prone_area_change_percent=0.0,
                    summary="Observed screening state from Sentinel-1 SAR plus Sentinel-2 optical water, snow, and vegetation proxies.",
                ),
                RiskProjection(
                    horizon_years=10,
                    label="10 years",
                    flood_risk=flood_risk_10,
                    landslide_risk=landslide_risk_10,
                    discharge_change_percent=round(discharge_10, 1),
                    flood_prone_area_change_percent=round(area_10, 1),
                    summary="Evidence-scaled scenario index. This is not yet a hydrological forecast; EFAS/Lisflood calibration is the next step.",
                ),
                RiskProjection(
                    horizon_years=20,
                    label="20 years",
                    flood_risk=flood_risk_20,
                    landslide_risk=landslide_risk_20,
                    discharge_change_percent=round(discharge_20, 1),
                    flood_prone_area_change_percent=round(area_20, 1),
                    summary="Scenario pressure increases where snow storage and low vegetation indicate faster runoff and weaker slope buffering.",
                ),
                RiskProjection(
                    horizon_years=50,
                    label="50 years",
                    flood_risk=flood_risk_50,
                    landslide_risk=landslide_risk_50,
                    discharge_change_percent=round(discharge_50, 1),
                    flood_prone_area_change_percent=round(area_50, 1),
                    summary="Long-horizon stress test derived from current Copernicus evidence plus climate-pressure assumptions.",
                ),
            ],
            impacts=[
                RiskImpact(
                    category="Exposure gap",
                    metric="Building and population layer",
                    value="Not connected",
                    detail="Current risk cannot estimate people or assets affected until local cadastral, building footprint, or population grids are added.",
                ),
                RiskImpact(
                    category="Infrastructure",
                    metric="Road and rail overlay",
                    value="Required next",
                    detail="Combine the AOI with OpenStreetMap or official transport layers to identify bridges, roads, and rail corridors intersecting screened water or slope-risk zones.",
                ),
                RiskImpact(
                    category="Hazard model gap",
                    metric="DEM and slope layer",
                    value="Pending",
                    detail="Landslide interpretation needs slope, aspect, geology, and rainfall/saturation layers. Current landslide risk is only an evidence-scaled proxy.",
                ),
                RiskImpact(
                    category="Economic use",
                    metric="Tourism and agriculture exposure",
                    value="Pending",
                    detail="Tourism facilities, farms, and access roads should be layered on top of the AOI to translate hazard screening into economic exposure.",
                ),
            ],
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
        )

    def _get_cached_inn_timeline(self) -> RiskTimeline | None:
        if not self._inn_cache or not self._inn_cached_at:
            return None

        if datetime.now(UTC) - self._inn_cached_at > RISK_TIMELINE_CACHE_TTL:
            return None

        return self._inn_cache

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

        return metrics

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
        horizon_years: int,
    ) -> Severity:
        score = self._severity_score(current)
        if ndwi_water_fraction >= 0.2:
            score += 1
        if horizon_years >= 20:
            score += 1
        if horizon_years >= 50:
            score += 1
        return self._severity_from_score(score)

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
        return self._severity_from_score(score)

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

    def _validate_aoi_bounds(self, bbox: AoiBounds) -> None:
        if bbox.west >= bbox.east or bbox.south >= bbox.north:
            raise ValueError("AOI bbox must be ordered as west < east and south < north")

        if bbox.west < -180 or bbox.east > 180 or bbox.south < -90 or bbox.north > 90:
            raise ValueError("AOI bbox is outside valid WGS84 bounds")

        if (bbox.east - bbox.west) > 1.2 or (bbox.north - bbox.south) > 1.2:
            raise ValueError("AOI bbox is too large for interactive screening; keep it below 1.2 degrees per side")

    def _aoi_cache_key(self, label: str, bbox: list[float]) -> str:
        rounded = ",".join(f"{value:.4f}" for value in bbox)
        return sha1(f"{label}:{rounded}".encode("utf-8")).hexdigest()


long_term_risk_service = LongTermRiskService()
