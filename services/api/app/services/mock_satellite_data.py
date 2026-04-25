import math
from app.models.environmental_analysis import (
    ProblemType,
    Severity,
    ProblemLocation,
    EnvironmentalProblem,
    ProblemCause,
    PreventionMeasure,
    EcosystemImpact,
    AreaAnalysis,
)


class MockSatelliteDataService:
    def __init__(self):
        self._scenarios = self._build_scenarios()

    def _build_scenarios(self) -> dict[str, dict]:
        return {
            "lake-balaton": {
                "name": "Lake Balaton",
                "latitude": 46.85,
                "longitude": 17.73,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-001",
                        type=ProblemType.eutrophication,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=46.85, longitude=17.73, radius_km=15.0),
                        detected_at="2026-04-24T10:00:00Z",
                        source="Sentinel-2 MSI",
                        description="High chlorophyll-a concentration detected (45.2 mg/m³), indicating severe eutrophication in the western basin.",
                    ),
                    EnvironmentalProblem(
                        id="prob-002",
                        type=ProblemType.oxygen_depletion,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=46.90, longitude=17.65, radius_km=8.0),
                        detected_at="2026-04-24T10:00:00Z",
                        source="Sentinel-3 OLCI",
                        description="Dissolved oxygen levels below 4 mg/L in hypolimnion layer, creating dead zones for aquatic life.",
                    ),
                    EnvironmentalProblem(
                        id="prob-003",
                        type=ProblemType.invasive_species,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=46.82, longitude=17.80, radius_km=10.0),
                        detected_at="2026-04-20T14:30:00Z",
                        source="Sentinel-2 MSI / Galileo GNSS",
                        description="Presence of invasive water hyacinth (Eichhornia crassipes) detected in shallow southern regions.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-001",
                        primary_cause="Excessive nutrient loading from agricultural runoff",
                        contributing_factors=[
                            "Intensive farming in catchment area",
                            "Insufficient buffer zones near shorelines",
                            "Wastewater treatment capacity exceeded",
                            "High phosphorus content in fertilizers",
                        ],
                        source_details="Copernicus Land Cover: 68% agricultural land in watershed; European Pollutant Release Register data shows 340 tonnes/year phosphorus discharge",
                    ),
                    ProblemCause(
                        problem_id="prob-002",
                        primary_cause="Stratification-induced oxygen depletion",
                        contributing_factors=[
                            "Warm water layer preventing oxygen exchange",
                            "Decomposition of algal biomass",
                            "Limited water flow/turnover",
                        ],
                        source_details="Sentinel-3 thermal data shows 8°C temperature differential between surface and bottom waters",
                    ),
                    ProblemCause(
                        problem_id="prob-003",
                        primary_cause="Climate change enabling tropical species survival",
                        contributing_factors=[
                            "Rising water temperatures (+2.1°C since 1990)",
                            "Reduced winter freezing periods",
                            "Boat traffic dispersing fragments",
                        ],
                        source_details="Galileo GPS tracking shows increased boat activity; Climate change: EU-SPI data indicates 2.1°C warming trend",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-001",
                        action="Implement constructed wetlands and buffer strips along tributaries",
                        feasibility="high",
                        estimated_cost="€2,500,000 - €4,000,000",
                        timeline="18-24 months for implementation, 3-5 years for measurable impact",
                    ),
                    PreventionMeasure(
                        problem_id="prob-001",
                        action="Upgrade wastewater treatment plants with advanced phosphorus removal",
                        feasibility="medium",
                        estimated_cost="€8,000,000 - €15,000,000",
                        timeline="36-48 months",
                    ),
                    PreventionMeasure(
                        problem_id="prob-002",
                        action="Install aeration/destratification systems in critical zones",
                        feasibility="medium",
                        estimated_cost="€500,000 - €1,200,000",
                        timeline="12-18 months",
                    ),
                    PreventionMeasure(
                        problem_id="prob-003",
                        action="Mechanical removal and biological control program",
                        feasibility="high",
                        estimated_cost="€300,000 - €600,000/year",
                        timeline="Ongoing annual program",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-001",
                        affected_species=["Common carp", "Pike", "European catfish", "Zooplankton community"],
                        habitat_impact="Loss of submerged macrophytes; turbidity preventing photosynthesis; algal toxins affecting food web",
                        duration="Long-term (5-10 years without intervention)",
                        recovery_potential="Medium - requires sustained nutrient reduction",
                    ),
                    EcosystemImpact(
                        problem_id="prob-002",
                        affected_species=["Trout", "Grayling", "Benthic invertebrates", "Macrozoobenthos"],
                        habitat_impact="Fish kills in deep areas; reduced biodiversity; altered benthic community structure",
                        duration="Medium-term (1-3 years with aeration)",
                        recovery_potential="High with active intervention",
                    ),
                    EcosystemImpact(
                        problem_id="prob-003",
                        affected_species=["Native water lilies", "Reed beds", "Native fish spawning areas", "Waterfowl"],
                        habitat_impact="Dense mats blocking sunlight; reduced oxygen; displaced native vegetation; hindered fish migration",
                        duration="Long-term if untreated (10+ years)",
                        recovery_potential="High with sustained control program",
                    ),
                ],
            },
            "danube-delta": {
                "name": "Danube Delta",
                "latitude": 45.15,
                "longitude": 29.65,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-004",
                        type=ProblemType.flood,
                        severity=Severity.critical,
                        location=ProblemLocation(latitude=45.20, longitude=29.80, radius_km=25.0),
                        detected_at="2026-04-24T06:00:00Z",
                        source="Sentinel-1 SAR",
                        description="Major flooding event affecting 340 km² of delta wetlands. Water levels 4.2m above normal.",
                    ),
                    EnvironmentalProblem(
                        id="prob-005",
                        type=ProblemType.chemical_pollution,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=45.10, longitude=29.50, radius_km=12.0),
                        detected_at="2026-04-23T11:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Hydrocarbon contamination detected in Sfântu Gheorghe channel. Suspected industrial discharge.",
                    ),
                    EnvironmentalProblem(
                        id="prob-006",
                        type=ProblemType.invasive_species,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=45.25, longitude=29.70, radius_km=18.0),
                        detected_at="2026-04-22T09:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Rapid expansion of invasive double-layered mussel (Dreissena rostriformis) in main channels.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-004",
                        primary_cause="Exceptional spring snowmelt and rainfall in Carpathian basin",
                        contributing_factors=[
                            "Above-average winter snowfall in upstream catchments",
                            "Rapid warming causing synchronized melt",
                            "Delta channel capacity reduced by sediment deposition",
                            "Limited floodplain connectivity due to dykes",
                        ],
                        source_details="Copernicus C3S seasonal forecast; GPM-IMERG precipitation data shows 180% of normal in March-April",
                    ),
                    ProblemCause(
                        problem_id="prob-005",
                        primary_cause="Illegal industrial discharge from upstream facilities",
                        contributing_factors=[
                            "Insufficient monitoring of industrial outfalls",
                            "Aging wastewater infrastructure",
                            "Economic pressure on compliance",
                        ],
                        source_details="EMSA satellite imagery shows regular discharge patterns; water quality sensors confirm hydrocarbon presence",
                    ),
                    ProblemCause(
                        problem_id="prob-006",
                        primary_cause="Ballast water introduction and climate-enabled reproduction",
                        contributing_factors=[
                            "Commercial shipping through delta",
                            "Rising water temperatures",
                            "High nutrient availability",
                        ],
                        source_details="Galileo tracking shows increased commercial vessel traffic; water temperature +1.8°C vs. 2020",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-004",
                        action="Restore floodplain connectivity by removing obsolete dykes",
                        feasibility="medium",
                        estimated_cost="€15,000,000 - €25,000,000",
                        timeline="5-7 years for full restoration",
                    ),
                    PreventionMeasure(
                        problem_id="prob-004",
                        action="Implement early warning system using Sentinel-1 time-series analysis",
                        feasibility="high",
                        estimated_cost="€800,000 - €1,200,000",
                        timeline="12 months for system deployment",
                    ),
                    PreventionMeasure(
                        problem_id="prob-005",
                        action="Install real-time water quality monitoring with satellite uplink",
                        feasibility="high",
                        estimated_cost="€400,000 - €600,000",
                        timeline="6-8 months",
                    ),
                    PreventionMeasure(
                        problem_id="prob-006",
                        action="Biological control using indigenous predators + mechanical removal",
                        feasibility="medium",
                        estimated_cost="€200,000 - €400,000/year",
                        timeline="Ongoing",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-004",
                        affected_species=["Pelicans (dalmatian and white)", "Sturgeons", "Wetland birds", "Common otter"],
                        habitat_impact="Temporary habitat destruction; Nesting site inundation; Fish spawning areas disrupted",
                        duration="Short-term (weeks to months for flood recession)",
                        recovery_potential="High - delta ecosystems are resilient",
                    ),
                    EcosystemImpact(
                        problem_id="prob-005",
                        affected_species=["Sturgeon species", "Catfish", "Benthic organisms", "Aquatic birds"],
                        habitat_impact="Bioaccumulation of toxins in food web; Fish mortality in affected channels; Contaminated sediment",
                        duration="Medium to long-term (2-5 years for sediment remediation)",
                        recovery_potential="Medium with active remediation",
                    ),
                    EcosystemImpact(
                        problem_id="prob-006",
                        affected_species=["Native unionid mussels", "Native fish", "Submerged vegetation"],
                        habitat_impact="Mussel populations decimated by colonization; Filter-feeding disrupts food web; Structural damage to infrastructure",
                        duration="Long-term (10+ years without control)",
                        recovery_potential="Low to medium without intervention",
                    ),
                ],
            },
            "lake-ohrid": {
                "name": "Lake Ohrid",
                "latitude": 41.02,
                "longitude": 20.72,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-007",
                        type=ProblemType.temperature_anomaly,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=41.02, longitude=20.72, radius_km=20.0),
                        detected_at="2026-04-24T12:00:00Z",
                        source="Sentinel-3 SLSTR",
                        description="Surface water temperature 2.5°C above seasonal average. Thermal stratification beginning 2 weeks early.",
                    ),
                    EnvironmentalProblem(
                        id="prob-008",
                        type=ProblemType.eutrophication,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=41.05, longitude=20.75, radius_km=8.0),
                        detected_at="2026-04-23T10:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Increased turbidity and algal growth in eastern shallower regions due to urban runoff.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-007",
                        primary_cause="Climate change accelerating regional warming",
                        contributing_factors=[
                            "Reduced winter cooling period",
                            "Earlier spring heating",
                            "Urban heat island effect on shoreline",
                        ],
                        source_details="Copernicus C3S shows 1.2°C regional temperature increase; Sentinel-3 confirms 14 consecutive months above average",
                    ),
                    ProblemCause(
                        problem_id="prob-008",
                        primary_cause="Untreated urban wastewater from Struga and Strumica",
                        contributing_factors=[
                            "Incomplete wastewater treatment coverage",
                            "Storm water overflow events",
                            "Agricultural runoff from surrounding fields",
                        ],
                        source_details="Urban population of 120,000 in catchment; treatment capacity covers only 65% of flow",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-007",
                        action="Establish temperature monitoring buoys with satellite telemetry",
                        feasibility="high",
                        estimated_cost="€150,000 - €250,000",
                        timeline="6 months for deployment",
                    ),
                    PreventionMeasure(
                        problem_id="prob-008",
                        action="Complete wastewater treatment infrastructure for Struga/Strumica",
                        feasibility="medium",
                        estimated_cost="€12,000,000 - €18,000,000",
                        timeline="36-48 months",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-007",
                        affected_species=["Ohrid trout (Salmo letnica)", "Endemic fish species", "Cold-water benthic community"],
                        habitat_impact="Altered spawning timing; thermal stress on cold-adapted species; potential regime shift to warmer community",
                        duration="Long-term (decades)",
                        recovery_potential="Low without climate action",
                    ),
                    EcosystemImpact(
                        problem_id="prob-008",
                        affected_species=["Endemic invertebrates", "Trout spawning areas", "Reed communities"],
                        habitat_impact="Reduced water clarity affecting spawning; Nutrient enrichment altering community structure",
                        duration="Medium-term (2-4 years with treatment upgrade)",
                        recovery_potential="High with infrastructure investment",
                    ),
                ],
            },
            "ebro-reservoir": {
                "name": "Ebro Reservoir",
                "latitude": 42.98,
                "longitude": -3.98,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-009",
                        type=ProblemType.drought,
                        severity=Severity.critical,
                        location=ProblemLocation(latitude=42.98, longitude=-3.98, radius_km=30.0),
                        detected_at="2026-04-24T08:00:00Z",
                        source="Sentinel-2 MSI / SMOS",
                        description="Reservoir at 28% capacity. Severe water stress in surrounding agricultural areas.",
                    ),
                    EnvironmentalProblem(
                        id="prob-010",
                        type=ProblemType.sediment_pollution,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=42.95, longitude=-4.05, radius_km=10.0),
                        detected_at="2026-04-22T11:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Significant sediment plume from erosion in upper catchment after recent heavy rainfall.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-009",
                        primary_cause="Prolonged drought conditions and reduced precipitation",
                        contributing_factors=[
                            "Three consecutive below-average rainfall years",
                            "Earlier snowmelt reducing spring recharge",
                            "High evaporation due to warming temperatures",
                            "Increased water demand from agriculture",
                        ],
                        source_details="Copernicus C3S drought indicator shows 18-month SPI below -2.0; SMOS soil moisture at record low",
                    ),
                    ProblemCause(
                        problem_id="prob-010",
                        primary_cause="Deforestation and poor land management in upper catchment",
                        contributing_factors=[
                            "Wildfire damage in 2025",
                            "Livestock overgrazing",
                            "Insufficient erosion control measures",
                        ],
                        source_details="Copernicus Land Cover shows 15% reduction in forest cover since 2024; burnt area mapping from Sentinel-2",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-009",
                        action="Implement drip irrigation optimization program",
                        feasibility="high",
                        estimated_cost="€800,000 - €1,500,000",
                        timeline="12-18 months",
                    ),
                    PreventionMeasure(
                        problem_id="prob-009",
                        action="Establish water allocation trading system",
                        feasibility="medium",
                        estimated_cost="€200,000 - €400,000 (system design)",
                        timeline="18-24 months",
                    ),
                    PreventionMeasure(
                        problem_id="prob-010",
                        action="Revegetation and erosion control in burnt areas",
                        feasibility="high",
                        estimated_cost="€600,000 - €1,000,000",
                        timeline="24-36 months for establishment",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-009",
                        affected_species=["European catfish", "Common barbel", "Riparian vegetation", "Wetland birds"],
                        habitat_impact="Reduced habitat connectivity; increased water temperature; stranding of fish in receding shallows",
                        duration="Long-term (requires sustained rainfall recovery)",
                        recovery_potential="Medium - dependent on climate patterns",
                    ),
                    EcosystemImpact(
                        problem_id="prob-010",
                        affected_species=["Benthic fish", "Native crayfish", "Spawning gravels"],
                        habitat_impact="Spawning gravel smothering; increased turbidity affecting gill function; habitat simplification",
                        duration="Medium-term (1-2 years post-vegetation recovery)",
                        recovery_potential="High with watershed restoration",
                    ),
                ],
            },
            "maas-river": {
                "name": "Maas River",
                "latitude": 51.92,
                "longitude": 4.47,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-011",
                        type=ProblemType.chemical_pollution,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=51.85, longitude=4.60, radius_km=8.0),
                        detected_at="2026-04-24T07:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Purple-brown discoloration detected downstream of industrial zone. Suspected chemical discharge.",
                    ),
                    EnvironmentalProblem(
                        id="prob-012",
                        type=ProblemType.temperature_anomaly,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=51.95, longitude=4.40, radius_km=12.0),
                        detected_at="2026-04-24T13:00:00Z",
                        source="Sentinel-3 SLSTR",
                        description="Thermal plume from power plant cooling, elevating river temperature by 3°C in discharge zone.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-011",
                        primary_cause="Industrial discharge from chemical processing facilities",
                        contributing_factors=[
                            "Aging infrastructure at chemical park",
                            "Insufficient treatment capacity during high production",
                            "Potential for illegal discharge during maintenance",
                        ],
                        source_details="EMSA data; European Industrial Emissions Portal shows 12 facilities in catchment with elevated risk",
                    ),
                    ProblemCause(
                        problem_id="prob-012",
                        primary_cause="Thermal discharge from energy generation",
                        contributing_factors=[
                            "Conventional cooling system design",
                            "Reduced flow during drought increasing concentration",
                        ],
                        source_details="Sentinel-3 thermal anomaly detection; power plant operational data",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-011",
                        action="Install continuous emissions monitoring at major industrial outfalls",
                        feasibility="high",
                        estimated_cost="€500,000 - €800,000",
                        timeline="12 months",
                    ),
                    PreventionMeasure(
                        problem_id="prob-012",
                        action="Upgrade to closed-loop cooling system or hybrid cooling towers",
                        feasibility="low",
                        estimated_cost="€25,000,000 - €40,000,000",
                        timeline="36-48 months",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-011",
                        affected_species=["Atlantic salmon", "European eel", "Starry sturgeon", "Benthic invertebrates"],
                        habitat_impact="Direct toxicity causing fish kills; bioaccumulation in food chain; loss of sensitive species",
                        duration="Variable depending on pollutant degradation",
                        recovery_potential="Medium with source control",
                    ),
                    EcosystemImpact(
                        problem_id="prob-012",
                        affected_species=["Salmonid species", "Trout perch", "Native crayfish"],
                        habitat_impact="Temperature-sensitive species displaced; increased metabolic demand; altered community composition",
                        duration="Continuous while plant operating",
                        recovery_potential="High with thermal mitigation",
                    ),
                ],
            },
        }

    def get_analysis_by_water_body(self, water_body_id: str) -> AreaAnalysis | None:
        scenario = self._scenarios.get(water_body_id)
        if not scenario:
            return None

        return AreaAnalysis(
            water_body_id=water_body_id,
            water_body_name=scenario["name"],
            latitude=scenario["latitude"],
            longitude=scenario["longitude"],
            problems=scenario["problems"],
            causes=scenario["causes"],
            prevention_measures=scenario["prevention"],
            ecosystem_impacts=scenario["impacts"],
        )

    def get_analysis_by_location(self, lat: float, lng: float, radius_km: float) -> AreaAnalysis:
        closest_scenario = None
        min_distance = float("inf")

        for water_body_id, scenario in self._scenarios.items():
            distance = self._haversine_distance(
                lat, lng, scenario["latitude"], scenario["longitude"]
            )
            if distance < min_distance:
                min_distance = distance
                closest_scenario = scenario
                closest_id = water_body_id

        if closest_scenario and min_distance <= radius_km:
            return AreaAnalysis(
                water_body_id=closest_id,
                water_body_name=closest_scenario["name"],
                latitude=closest_scenario["latitude"],
                longitude=closest_scenario["longitude"],
                problems=closest_scenario["problems"],
                causes=closest_scenario["causes"],
                prevention_measures=closest_scenario["prevention"],
                ecosystem_impacts=closest_scenario["impacts"],
            )

        return AreaAnalysis(
            water_body_id=None,
            water_body_name=None,
            latitude=lat,
            longitude=lng,
            problems=[],
            causes=[],
            prevention_measures=[],
            ecosystem_impacts=[],
        )

    def _haversine_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c


mock_satellite_service = MockSatelliteDataService()