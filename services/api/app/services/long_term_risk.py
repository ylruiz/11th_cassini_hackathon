from __future__ import annotations

from datetime import UTC, datetime, timedelta

from app.models.environmental_analysis import (
    RiskAction,
    RiskDriver,
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

    async def get_risk_timeline(self, water_body_id: str) -> RiskTimeline | None:
        if water_body_id != "inn-river":
            return None

        cached = self._get_cached_inn_timeline()
        if cached:
            return cached

        flood_analysis = await copernicus_flood_service.get_inn_river_analysis()
        flood_problem = flood_analysis.problems[0]

        timeline = RiskTimeline(
            water_body_id="inn-river",
            water_body_name="Inn River",
            generated_at=datetime.now(UTC).isoformat().replace("+00:00", "Z"),
            confidence="Medium - current flood signal is live Copernicus data; long-term values are MVP scenario assumptions pending CDS/Lisflood calibration.",
            current_signal=RiskSignal(
                label="Current flood signal",
                value=flood_problem.severity.value.upper(),
                severity=flood_problem.severity,
                source=flood_problem.source,
                summary=flood_problem.description,
            ),
            drivers=[
                RiskDriver(
                    id="surface-water",
                    label="Surface-water expansion",
                    status="Active",
                    trend="Increasing",
                    detail=(
                        "Sentinel-1 SAR detected more water-like backscatter across the selected Inn River AOI "
                        "during the last 30 days."
                    ),
                    source="Copernicus Sentinel-1 GRD",
                ),
                RiskDriver(
                    id="snowmelt",
                    label="Earlier alpine snowmelt",
                    status="Scenario driver",
                    trend="Earlier spring peaks",
                    detail=(
                        "Warmer springs reduce snow-storage buffering and can concentrate runoff into shorter, "
                        "sharper flood pulses."
                    ),
                    source="Copernicus CDS / C3S scenario assumption",
                ),
                RiskDriver(
                    id="glacier-storage",
                    label="Reduced glacier storage",
                    status="Long-term pressure",
                    trend="Declining cold-water reserve",
                    detail=(
                        "Shrinking glacier mass lowers late-season storage and increases sensitivity to intense "
                        "rain-on-snow events in alpine catchments."
                    ),
                    source="Glacierized catchment scenario assumption",
                ),
                RiskDriver(
                    id="slope-instability",
                    label="Slope saturation and instability",
                    status="Watch",
                    trend="Higher landslide susceptibility",
                    detail=(
                        "Repeated flood pulses and saturated valley slopes can raise debris-flow and landslide "
                        "susceptibility near infrastructure corridors."
                    ),
                    source="DEM / local hazard layer placeholder",
                ),
            ],
            projections=[
                RiskProjection(
                    horizon_years=0,
                    label="Today",
                    flood_risk=flood_problem.severity,
                    landslide_risk=Severity.medium,
                    discharge_change_percent=0.0,
                    flood_prone_area_change_percent=0.0,
                    summary="Live Sentinel-1 signal shows elevated surface-water extent in the selected AOI.",
                ),
                RiskProjection(
                    horizon_years=10,
                    label="10 years",
                    flood_risk=Severity.high,
                    landslide_risk=Severity.medium,
                    discharge_change_percent=8.0,
                    flood_prone_area_change_percent=6.0,
                    summary="Earlier melt and more intense rainfall events increase peak-flow stress.",
                ),
                RiskProjection(
                    horizon_years=20,
                    label="20 years",
                    flood_risk=Severity.high,
                    landslide_risk=Severity.high,
                    discharge_change_percent=14.0,
                    flood_prone_area_change_percent=12.0,
                    summary="Reduced snow and glacier buffering increases flood pulses and slope saturation risk.",
                ),
                RiskProjection(
                    horizon_years=50,
                    label="50 years",
                    flood_risk=Severity.critical,
                    landslide_risk=Severity.high,
                    discharge_change_percent=24.0,
                    flood_prone_area_change_percent=21.0,
                    summary="Without adaptation, exposed settlements and transport routes face recurring high-loss events.",
                ),
            ],
            impacts=[
                RiskImpact(
                    category="Settlements",
                    metric="Potentially exposed villages",
                    value="3 priority clusters",
                    detail="Use local cadastral/building data next to replace this MVP exposure estimate.",
                ),
                RiskImpact(
                    category="Transport",
                    metric="Road and rail corridors",
                    value="15 km watch zone",
                    detail="Valley-floor infrastructure is the first asset class to prioritize for detailed screening.",
                ),
                RiskImpact(
                    category="Insurance",
                    metric="Loss pressure",
                    value="Rising",
                    detail="Repeated flood and landslide events can increase payouts, crisis response cost, and local premiums.",
                ),
                RiskImpact(
                    category="Tourism and agriculture",
                    metric="Economic continuity",
                    value="Seasonal disruption risk",
                    detail="Flooded access roads and unstable slopes can interrupt farms, hotels, and recreation areas.",
                ),
            ],
            actions=[
                RiskAction(
                    priority="Immediate",
                    title="Validate Sentinel-1 flood signal with gauges and municipal reports",
                    timeline="Today",
                    expected_effect="Confirms whether the detected water-like area is active inundation or saturated ground.",
                    estimated_cost="Operational monitoring",
                ),
                RiskAction(
                    priority="Near-term",
                    title="Add EFAS/Lisflood discharge forecast sampling for the Inn catchment",
                    timeline="1-2 weeks",
                    expected_effect="Turns the timeline from scenario assumptions into calibrated discharge-risk values.",
                    estimated_cost="Low once CDS access is configured",
                ),
                RiskAction(
                    priority="Planning",
                    title="Prioritize retention zones and slope inspections near exposed corridors",
                    timeline="3-12 months",
                    expected_effect="Reduces peak-flow pressure and catches landslide-prone slopes before failure.",
                    estimated_cost="Medium",
                ),
            ],
        )

        self._inn_cache = timeline
        self._inn_cached_at = datetime.now(UTC)
        return timeline

    def _get_cached_inn_timeline(self) -> RiskTimeline | None:
        if not self._inn_cache or not self._inn_cached_at:
            return None

        if datetime.now(UTC) - self._inn_cached_at > RISK_TIMELINE_CACHE_TTL:
            return None

        return self._inn_cache


long_term_risk_service = LongTermRiskService()
