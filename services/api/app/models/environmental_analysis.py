from pydantic import BaseModel, Field
from enum import Enum


class ProblemType(str, Enum):
    eutrophication = "eutrophication"
    chemical_pollution = "chemical_pollution"
    flood = "flood"
    drought = "drought"
    temperature_anomaly = "temperature_anomaly"
    invasive_species = "invasive_species"
    sediment_pollution = "sediment_pollution"
    oxygen_depletion = "oxygen_depletion"


class Severity(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class ProblemLocation(BaseModel):
    latitude: float
    longitude: float
    radius_km: float


class EnvironmentalProblem(BaseModel):
    id: str
    type: ProblemType
    severity: Severity
    location: ProblemLocation
    detected_at: str
    source: str
    description: str


class ProblemCause(BaseModel):
    problem_id: str
    primary_cause: str
    contributing_factors: list[str]
    source_details: str


class PreventionMeasure(BaseModel):
    problem_id: str
    action: str
    feasibility: str
    estimated_cost: str
    timeline: str
    cost_if_nothing_done: str


class EcosystemImpact(BaseModel):
    problem_id: str
    affected_species: list[str]
    habitat_impact: str
    duration: str
    recovery_potential: str


class AreaAnalysis(BaseModel):
    water_body_id: str | None = None
    water_body_name: str | None = None
    latitude: float
    longitude: float
    problems: list[EnvironmentalProblem]
    causes: list[ProblemCause]
    prevention_measures: list[PreventionMeasure]
    ecosystem_impacts: list[EcosystemImpact]


class RiskSignal(BaseModel):
    label: str
    value: str
    severity: Severity
    source: str
    summary: str


class RiskDriver(BaseModel):
    id: str
    label: str
    status: str
    trend: str
    detail: str
    source: str


class RiskProjection(BaseModel):
    horizon_years: int
    label: str
    flood_risk: Severity
    landslide_risk: Severity
    discharge_change_percent: float
    flood_prone_area_change_percent: float
    summary: str


class RiskImpact(BaseModel):
    category: str
    metric: str
    value: str
    detail: str


class RiskAction(BaseModel):
    priority: str
    title: str
    timeline: str
    expected_effect: str
    estimated_cost: str


class RiskEvidenceMetric(BaseModel):
    label: str
    value: float
    unit: str
    fraction: float
    interpretation: str
    source: str


class Settlement(BaseModel):
    name: str
    latitude: float
    longitude: float
    population: int
    kind: str
    region: str
    distance_km: float


class SettlementExposure(BaseModel):
    total_settlements: int
    total_population: int
    inside_aoi: int
    within_buffer: int
    buffer_km: float
    settlements: list[Settlement]


class RiskWeights(BaseModel):
    """Multipliers (0.0 - 2.0) applied to the four evidence channels.

    Default 1.0 reproduces the canonical timeline. Bounds keep the model in a
    sane regime; 0 fully suppresses a channel, 2 doubles its push on
    projections.
    """

    snow: float = Field(default=1.0, ge=0.0, le=2.0)
    surface_water: float = Field(default=1.0, ge=0.0, le=2.0)
    vegetation: float = Field(default=1.0, ge=0.0, le=2.0)
    hydrology: float = Field(default=1.0, ge=0.0, le=2.0)

    def is_default(self) -> bool:
        return all(
            abs(value - 1.0) < 1e-9
            for value in (self.snow, self.surface_water, self.vegetation, self.hydrology)
        )


class HistoryPoint(BaseModel):
    month: str
    ndsi_snow_fraction: float
    efas_anomaly_percent: float


class AoiHistory(BaseModel):
    label: str
    source: str
    provenance: str
    points: list[HistoryPoint]


class RiskTimeline(BaseModel):
    water_body_id: str
    water_body_name: str
    generated_at: str
    analysis_period_days: int
    aoi_area_km2: float
    confidence_label: str
    confidence: str
    methodology_note: str
    observed_data_sources: list[str]
    scenario_assumptions: list[str]
    missing_operational_layers: list[str]
    current_signal: RiskSignal
    drivers: list[RiskDriver]
    projections: list[RiskProjection]
    impacts: list[RiskImpact]
    actions: list[RiskAction]
    evidence: list[RiskEvidenceMetric]
    settlement_exposure: SettlementExposure | None = None
    weights: RiskWeights | None = None


class AoiBounds(BaseModel):
    west: float
    south: float
    east: float
    north: float


class AoiRiskTimelineRequest(BaseModel):
    label: str = "Custom Alpine AOI"
    bbox: AoiBounds
    weights: RiskWeights | None = None