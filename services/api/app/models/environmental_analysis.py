from pydantic import BaseModel
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


class AoiBounds(BaseModel):
    west: float
    south: float
    east: float
    north: float


class AoiRiskTimelineRequest(BaseModel):
    label: str = "Custom Alpine AOI"
    bbox: AoiBounds