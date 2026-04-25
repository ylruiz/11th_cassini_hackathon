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