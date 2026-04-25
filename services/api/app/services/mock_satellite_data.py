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
            "tisza-river": {
                "name": "Tisza River",
                "latitude": 47.59,
                "longitude": 21.12,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-001",
                        type=ProblemType.flood,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=47.55, longitude=21.20, radius_km=20.0),
                        detected_at="2026-04-24T08:00:00Z",
                        source="Sentinel-1 SAR",
                        description="Flash flooding affecting 180 km² of floodplain. Water levels 3.8m above normal at Tokaj.",
                    ),
                    EnvironmentalProblem(
                        id="prob-002",
                        type=ProblemType.chemical_pollution,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=47.65, longitude=21.05, radius_km=12.0),
                        detected_at="2026-04-23T10:00:00Z",
                        source="Sentinel-2 MSI",
                        description="High salinity plume detected (conductivity 4,200 µS/cm). Suspected industrial brine discharge.",
                    ),
                    EnvironmentalProblem(
                        id="prob-003",
                        type=ProblemType.eutrophication,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=47.50, longitude=21.15, radius_km=10.0),
                        detected_at="2026-04-22T11:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Algal bloom development in upstream reservoirs. Chlorophyll-a levels at 35 mg/m³.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-001",
                        primary_cause="Exceptional spring rainfall in Carpathian catchments",
                        contributing_factors=[
                            "Above-average winter precipitation in Tatra mountains",
                            "Rapid snowmelt combined with rain events",
                            "Channelization reducing floodplain storage",
                            "Debris accumulation narrowing river cross-section",
                        ],
                        source_details="Copernicus GPM-IMERG shows 220% of normal precipitation in March; Sentinel-1 flood extent mapping",
                    ),
                    ProblemCause(
                        problem_id="prob-002",
                        primary_cause="Industrial brine discharge from mining operations",
                        contributing_factors=[
                            "Legacy salt mining waste disposal",
                            "Inadequate treatment of industrial effluent",
                            "Low river flow diluting capacity",
                        ],
                        source_details="European Pollutant Release Register shows 12 mining operations in catchment; water quality sensors confirm elevated chloride",
                    ),
                    ProblemCause(
                        problem_id="prob-003",
                        primary_cause="Nutrient loading from agricultural diffuse sources",
                        contributing_factors=[
                            "Intensive corn and sunflower cultivation",
                            "Livestock operations in riparian zones",
                            "Insufficient buffer strips",
                        ],
                        source_details="Copernicus Land Cover: 58% agricultural land; phosphorus loads estimated at 280 tonnes/year",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-001",
                        action="Restore floodplain connectivity through dyke removal",
                        feasibility="medium",
                        estimated_cost="€8M - €12M",
                        timeline="3-5 years",
                        cost_if_nothing_done="€35M - €50M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-001",
                        action="Implement early warning system using Sentinel-1 radar",
                        feasibility="high",
                        estimated_cost="€400K - €600K",
                        timeline="8-12 months",
                        cost_if_nothing_done="€15M - €25M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-002",
                        action="Enforce zero-discharge standards for mining operations",
                        feasibility="medium",
                        estimated_cost="€3M - €5M",
                        timeline="24-36 months",
                        cost_if_nothing_done="€20M - €30M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-003",
                        action="Establish riparian buffer zones and constructed wetlands",
                        feasibility="high",
                        estimated_cost="€1.5M - €2.5M",
                        timeline="12-18 months",
                        cost_if_nothing_done="€18M - €28M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-001",
                        affected_species=["European catfish", "Pike", "Sterlet sturgeon", "European otter"],
                        habitat_impact="Floodplain habitat destruction; fish spawning areas inundated; riparian forest damage",
                        duration="Short to medium-term (weeks to months)",
                        recovery_potential="High with floodplain restoration",
                    ),
                    EcosystemImpact(
                        problem_id="prob-002",
                        affected_species=["Freshwater fish community", "Macrozoobenthos", "Riparian vegetation"],
                        habitat_impact="Salinity stress on freshwater species; altered plant community composition; reduced biodiversity",
                        duration="Long-term without source control",
                        recovery_potential="Medium with brine treatment",
                    ),
                    EcosystemImpact(
                        problem_id="prob-003",
                        affected_species=["Native fish", "Aquatic invertebrates", "Waterfowl"],
                        habitat_impact="Hypoxic conditions causing fish kills; altered food web; reduced water clarity",
                        duration="Medium-term (1-2 years with mitigation)",
                        recovery_potential="High with nutrient reduction",
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
                        estimated_cost="€15M - €25M",
                        timeline="5-7 years for full restoration",
                        cost_if_nothing_done="€100M+",
                    ),
                    PreventionMeasure(
                        problem_id="prob-004",
                        action="Implement early warning system using Sentinel-1 time-series analysis",
                        feasibility="high",
                        estimated_cost="€800K - €1.2M",
                        timeline="12 months for system deployment",
                        cost_if_nothing_done="€20M - €35M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-005",
                        action="Install real-time water quality monitoring with satellite uplink",
                        feasibility="high",
                        estimated_cost="€400K - €600K",
                        timeline="6-8 months",
                        cost_if_nothing_done="€30M - €50M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-006",
                        action="Biological control using indigenous predators + mechanical removal",
                        feasibility="medium",
                        estimated_cost="€200K - €400K/yr",
                        timeline="Ongoing",
                        cost_if_nothing_done="€15M - €25M",
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
                        estimated_cost="€150K - €250K",
                        timeline="6 months for deployment",
                        cost_if_nothing_done="€12M - €20M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-008",
                        action="Complete wastewater treatment infrastructure for Struga/Strumica",
                        feasibility="medium",
                        estimated_cost="€12M - €18M",
                        timeline="36-48 months",
                        cost_if_nothing_done="€40M - €60M",
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
            "guadalquivir-river": {
                "name": "Guadalquivir River",
                "latitude": 36.78,
                "longitude": -6.43,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-009",
                        type=ProblemType.drought,
                        severity=Severity.critical,
                        location=ProblemLocation(latitude=37.39, longitude=-5.99, radius_km=35.0),
                        detected_at="2026-04-24T08:00:00Z",
                        source="Sentinel-2 MSI / SMOS",
                        description="River flow at 18% of average. Severe water stress in Doñana wetlands and agricultural zones.",
                    ),
                    EnvironmentalProblem(
                        id="prob-010",
                        type=ProblemType.eutrophication,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=37.20, longitude=-6.10, radius_km=15.0),
                        detected_at="2026-04-22T10:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Algal bloom in estuarine marshes near Sanlúcar. Chlorophyll-a concentrations at 65 mg/m³.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-009",
                        primary_cause="Prolonged drought and reduced precipitation",
                        contributing_factors=[
                            "Three consecutive below-average rainfall years",
                            "Earlier snowmelt in Sierra Nevada",
                            "High evaporation rates",
                            "Intensive agricultural water extraction",
                        ],
                        source_details="Copernicus C3S shows 24-month SPI below -1.8; SMOS soil moisture at record low; reservoir levels at 25%",
                    ),
                    ProblemCause(
                        problem_id="prob-010",
                        primary_cause="Nutrient enrichment from agricultural runoff",
                        contributing_factors=[
                            "Intensive greenhouse agriculture in Almería corridor",
                            "Livestock operations upstream",
                            "Reduced flow diluting pollutants",
                            "Wastewater treatment overflow",
                        ],
                        source_details="Copernicus Land Cover shows 45% agricultural land; European Pollutant Release Register shows elevated nitrogen loads",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-009",
                        action="Implement drip irrigation and water efficiency program",
                        feasibility="high",
                        estimated_cost="€1.2M - €2M",
                        timeline="12-18 months",
                        cost_if_nothing_done="€60M - €90M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-009",
                        action="Establish managed aquifer recharge from treated wastewater",
                        feasibility="medium",
                        estimated_cost="€8M - €12M",
                        timeline="36-48 months",
                        cost_if_nothing_done="€40M - €60M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-010",
                        action="Construct wetland treatment cells for agricultural runoff",
                        feasibility="high",
                        estimated_cost="€500K - €800K",
                        timeline="12 months",
                        cost_if_nothing_done="€15M - €25M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-009",
                        affected_species=["Doñana wetland birds", "Spanish imperial eagle", "European eel", "Marsh terrapin"],
                        habitat_impact="Wetland habitat shrinkage; reduced bird nesting success; fish stranding; dune migration",
                        duration="Long-term (requires sustained rainfall recovery)",
                        recovery_potential="Medium - dependent on climate patterns",
                    ),
                    EcosystemImpact(
                        problem_id="prob-010",
                        affected_species=["Migratory fish", "Estuarine invertebrates", "Flamingos", "Seagrass beds"],
                        habitat_impact="Hypoxic conditions in marshes; altered species composition; toxin accumulation in food web",
                        duration="Medium-term (1-3 years with nutrient reduction)",
                        recovery_potential="High with wetland restoration",
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
                        estimated_cost="€500K - €800K",
                        timeline="12 months",
                        cost_if_nothing_done="€60M - €100M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-012",
                        action="Upgrade to closed-loop cooling system or hybrid cooling towers",
                        feasibility="low",
                        estimated_cost="€25M - €40M",
                        timeline="36-48 months",
                        cost_if_nothing_done="€10M - €18M",
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
            "inn-river": {
                "name": "Inn River",
                "latitude": 48.57,
                "longitude": 13.43,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-013",
                        type=ProblemType.temperature_anomaly,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=47.30, longitude=11.45, radius_km=10.0),
                        detected_at="2026-04-24T12:00:00Z",
                        source="Sentinel-3 SLSTR",
                        description="Surface water temperature 2.8°C above seasonal average due to reduced glacial melt contribution.",
                    ),
                    EnvironmentalProblem(
                        id="prob-014",
                        type=ProblemType.sediment_pollution,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=47.20, longitude=11.35, radius_km=8.0),
                        detected_at="2026-04-23T09:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Significant sediment plume from construction activity in upper catchment. Turbidity exceeding 80 NTU.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-013",
                        primary_cause="Climate change reducing Alpine glacier coverage",
                        contributing_factors=[
                            "Accelerated glacier retreat",
                            "Earlier spring snowmelt",
                            "Reduced cold water inputs",
                        ],
                        source_details="Copernicus Climate Change Service shows 1.4°C regional warming; Sentinel-3 confirms 12 consecutive months above average",
                    ),
                    ProblemCause(
                        problem_id="prob-014",
                        primary_cause="Uncontrolled construction and infrastructure projects",
                        contributing_factors=[
                            "Highway expansion projects near river",
                            "Insufficient erosion control measures",
                            "Lack of sediment basins",
                        ],
                        source_details="Copernicus Land Cover change detection; construction permits show 3 major projects in catchment",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-013",
                        action="Establish long-term temperature monitoring network",
                        feasibility="high",
                        estimated_cost="€200K - €350K",
                        timeline="6 months for deployment",
                        cost_if_nothing_done="€8M - €15M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-014",
                        action="Enforce sediment control measures for construction projects",
                        feasibility="high",
                        estimated_cost="€150K - €300K",
                        timeline="Immediate with regulation",
                        cost_if_nothing_done="€5M - €10M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-013",
                        affected_species=["Brown trout", "Grayling", "Alpine amphibian species", "Cold-water invertebrates"],
                        habitat_impact="Altered spawning timing; thermal stress on cold-adapted species; reduced habitat suitability",
                        duration="Long-term (decades)",
                        recovery_potential="Low without climate action",
                    ),
                    EcosystemImpact(
                        problem_id="prob-014",
                        affected_species=["Fish spawning areas", "Benthic invertebrates", "Riparian vegetation"],
                        habitat_impact="Spawning gravel smothering; reduced photosynthesis; invertebrate community decline",
                        duration="Short-term (months) post-construction",
                        recovery_potential="High with erosion control",
                    ),
                ],
            },
            "maritsa-river": {
                "name": "Maritsa River",
                "latitude": 41.65,
                "longitude": 26.20,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-015",
                        type=ProblemType.chemical_pollution,
                        severity=Severity.critical,
                        location=ProblemLocation(latitude=42.10, longitude=25.40, radius_km=15.0),
                        detected_at="2026-04-24T07:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Heavy metal contamination detected (lead 5x, cadmium 3x above limits) near mining discharge point.",
                    ),
                    EnvironmentalProblem(
                        id="prob-016",
                        type=ProblemType.drought,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=42.05, longitude=25.25, radius_km=25.0),
                        detected_at="2026-04-23T10:00:00Z",
                        source="Sentinel-2 MSI / SMOS",
                        description="River flow at 22% of seasonal average. Severe water scarcity affecting irrigation.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-015",
                        primary_cause="Legacy mining waste and active mining operations",
                        contributing_factors=[
                            "Abandoned mines leaching heavy metals",
                            "Active mining effluent discharge",
                            "Inadequate wastewater treatment",
                            "Sediment resuspension during low flow",
                        ],
                        source_details="European Pollutant Release Register shows 8 mining facilities; historical mining sites with acid mine drainage",
                    ),
                    ProblemCause(
                        problem_id="prob-016",
                        primary_cause="Prolonged drought and excessive water extraction",
                        contributing_factors=[
                            "Four consecutive dry years",
                            "Intensive irrigation for agriculture",
                            "Reduced transboundary flow from Greece",
                            "Climate change affecting precipitation patterns",
                        ],
                        source_details="Copernicus C3S shows 30-month SPI below -1.5; river gauge data confirms record low flows",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-015",
                        action="Remediate legacy mining sites and install treatment systems",
                        feasibility="medium",
                        estimated_cost="€15M - €25M",
                        timeline="5-7 years",
                        cost_if_nothing_done="€40M - €60M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-015",
                        action="Implement real-time water quality monitoring network",
                        feasibility="high",
                        estimated_cost="€400K - €600K",
                        timeline="8-12 months",
                        cost_if_nothing_done="€12M - €18M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-016",
                        action="Promote water-efficient irrigation techniques",
                        feasibility="high",
                        estimated_cost="€2M - €4M",
                        timeline="18-24 months",
                        cost_if_nothing_done="€50M - €80M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-015",
                        affected_species=["Fish community", "Aquatic birds", "Riparian mammals"],
                        habitat_impact="Bioaccumulation of heavy metals; fish mortality events; contamination of food web",
                        duration="Long-term (decades without remediation)",
                        recovery_potential="Low to medium with active remediation",
                    ),
                    EcosystemImpact(
                        problem_id="prob-016",
                        affected_species=["Wetland birds", "Fish", "Riparian ecosystems"],
                        habitat_impact="Habitat shrinkage; fish stranding; loss of wetlands; reduced biodiversity",
                        duration="Long-term (requires sustained rainfall)",
                        recovery_potential="Medium with water management",
                    ),
                ],
            },
            "glomma-river": {
                "name": "Glomma River",
                "latitude": 59.91,
                "longitude": 10.27,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-017",
                        type=ProblemType.oxygen_depletion,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=59.85, longitude=10.35, radius_km=12.0),
                        detected_at="2026-04-24T10:00:00Z",
                        source="Sentinel-3 OLCI",
                        description="Dissolved oxygen levels below 5 mg/L in lower reaches, creating hypoxic conditions.",
                    ),
                    EnvironmentalProblem(
                        id="prob-018",
                        type=ProblemType.sediment_pollution,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=59.95, longitude=10.20, radius_km=8.0),
                        detected_at="2026-04-22T11:00:00Z",
                        source="Sentinel-2 MSI",
                        description="High turbidity event from forestry operations in upper catchment. Sediment loads 4x normal.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-017",
                        primary_cause="Reduced flow from hydroelectric regulation",
                        contributing_factors=[
                            "Dam operations reducing downstream flow",
                            "Warm water release from reservoirs",
                            "Low precipitation year",
                        ],
                        source_details="Norwegian Water Resources and Energy Directorate data; Sentinel-3 thermal data confirms warming",
                    ),
                    ProblemCause(
                        problem_id="prob-018",
                        primary_cause="Forestry operations near watercourses",
                        contributing_factors=[
                            "Clear-cutting in riparian zones",
                            "Insufficient buffer strips",
                            "Heavy rainfall mobilizing sediments",
                        ],
                        source_details="Copernicus Land Cover shows forestry expansion; satellite imagery confirms recent logging operations",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-017",
                        action="Implement environmental flow requirements for hydroelectric operations",
                        feasibility="medium",
                        estimated_cost="€1M - €2M",
                        timeline="12-24 months for regulatory change",
                        cost_if_nothing_done="€8M - €15M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-018",
                        action="Enforce riparian buffer zones for forestry operations",
                        feasibility="high",
                        estimated_cost="€300K - €500K",
                        timeline="Immediate with regulation",
                        cost_if_nothing_done="€4M - €8M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-017",
                        affected_species=["Atlantic salmon", "Sea trout", "European grayling", "Benthic invertebrates"],
                        habitat_impact="Reduced spawning success; fish kills in low oxygen zones; altered migration patterns",
                        duration="Medium-term (1-3 years with flow management)",
                        recovery_potential="High with environmental flows",
                    ),
                    EcosystemImpact(
                        problem_id="prob-018",
                        affected_species=["Salmonid spawning areas", "Freshwater crayfish", "Fish eggs"],
                        habitat_impact="Spawning gravel smothering; reduced invertebrate abundance; habitat degradation",
                        duration="Short to medium-term",
                        recovery_potential="High with buffer restoration",
                    ),
                ],
            },
            "vistula-river": {
                "name": "Vistula River",
                "latitude": 52.42,
                "longitude": 17.05,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-019",
                        type=ProblemType.flood,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=52.70, longitude=19.10, radius_km=30.0),
                        detected_at="2026-04-24T06:00:00Z",
                        source="Sentinel-1 SAR",
                        description="Major flooding affecting 420 km² of floodplain. Water levels 4.5m above normal near Toruń.",
                    ),
                    EnvironmentalProblem(
                        id="prob-020",
                        type=ProblemType.eutrophication,
                        severity=Severity.medium,
                        location=ProblemLocation(latitude=52.50, longitude=18.80, radius_km=18.0),
                        detected_at="2026-04-23T10:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Widespread algal bloom in lower Vistula. Chlorophyll-a concentrations reaching 55 mg/m³.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-019",
                        primary_cause="Exceptional spring snowmelt and rainfall",
                        contributing_factors=[
                            "Heavy winter snowfall in Carpathians",
                            "Rapid warming causing synchronized melt",
                            "Channel modifications reducing flood capacity",
                            "Ice jam formation",
                        ],
                        source_details="Copernicus GPM-IMERG shows 200% of normal precipitation; Sentinel-1 flood extent mapping confirms 420 km²",
                    ),
                    ProblemCause(
                        problem_id="prob-020",
                        primary_cause="Agricultural nutrient loading",
                        contributing_factors=[
                            "Intensive grain and root crop cultivation",
                            "Insufficient buffer strips",
                            "Livestock operations in floodplain",
                            "Wastewater treatment overflow",
                        ],
                        source_details="Copernicus Land Cover: 62% agricultural land; European Pollutant Release Register shows 450 tonnes/year phosphorus",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-019",
                        action="Restore floodplain connectivity through dyke removal",
                        feasibility="medium",
                        estimated_cost="€20M - €35M",
                        timeline="5-8 years",
                        cost_if_nothing_done="€80M - €120M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-019",
                        action="Deploy early warning system with Sentinel-1 analysis",
                        feasibility="high",
                        estimated_cost="€600K - €900K",
                        timeline="10-14 months",
                        cost_if_nothing_done="€25M - €40M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-020",
                        action="Implement precision agriculture and buffer strips program",
                        feasibility="high",
                        estimated_cost="€3M - €5M",
                        timeline="18-24 months",
                        cost_if_nothing_done="€30M - €50M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-019",
                        affected_species=["European catfish", "Pike", "Sturgeon", "European otter", "Wetland birds"],
                        habitat_impact="Floodplain habitat destruction; nesting site loss; fish spawning disruption; agricultural damage",
                        duration="Short-term (weeks to months)",
                        recovery_potential="High - floodplain ecosystems are resilient",
                    ),
                    EcosystemImpact(
                        problem_id="prob-020",
                        affected_species=["Fish community", "Benthic invertebrates", "Waterfowl", "Mammals"],
                        habitat_impact="Hypoxic fish kills; altered food web; reduced biodiversity; toxin exposure",
                        duration="Medium-term (2-4 years with mitigation)",
                        recovery_potential="High with nutrient reduction",
                    ),
                ],
            },
            "po-river": {
                "name": "Po River",
                "latitude": 45.18,
                "longitude": 9.40,
                "problems": [
                    EnvironmentalProblem(
                        id="prob-021",
                        type=ProblemType.drought,
                        severity=Severity.critical,
                        location=ProblemLocation(latitude=45.44, longitude=9.14, radius_km=40.0),
                        detected_at="2026-04-24T08:00:00Z",
                        source="Sentinel-2 MSI / SMOS",
                        description="River flow at 15% of average. Severe water crisis affecting agriculture and industry in Lombardy.",
                    ),
                    EnvironmentalProblem(
                        id="prob-022",
                        type=ProblemType.chemical_pollution,
                        severity=Severity.high,
                        location=ProblemLocation(latitude=45.20, longitude=9.30, radius_km=15.0),
                        detected_at="2026-04-23T09:00:00Z",
                        source="Sentinel-2 MSI",
                        description="Industrial chemical contamination detected downstream of Milan. Multiple pollutant signatures identified.",
                    ),
                ],
                "causes": [
                    ProblemCause(
                        problem_id="prob-021",
                        primary_cause="Prolonged drought and reduced Alpine snowpack",
                        contributing_factors=[
                            "Three consecutive dry years",
                            "Reduced winter precipitation in Alps",
                            "High summer temperatures increasing evaporation",
                            "Extensive agricultural water use",
                        ],
                        source_details="Copernicus C3S shows 24-month SPI below -2.0; SMOS soil moisture at record low; reservoir levels critical",
                    ),
                    ProblemCause(
                        problem_id="prob-022",
                        primary_cause="Industrial discharge from Milan metropolitan area",
                        contributing_factors=[
                            "Aging wastewater infrastructure",
                            "Combined sewer overflows",
                            "Industrial zone runoff",
                            "Historical contamination from textile industry",
                        ],
                        source_details="European Industrial Emissions Portal shows 45 facilities in catchment; water quality sensors confirm multiple contaminants",
                    ),
                ],
                "prevention": [
                    PreventionMeasure(
                        problem_id="prob-021",
                        action="Implement comprehensive water efficiency program",
                        feasibility="high",
                        estimated_cost="€5M - €8M",
                        timeline="24-36 months",
                        cost_if_nothing_done="€100M - €150M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-021",
                        action="Upgrade reservoir storage and managed aquifer recharge",
                        feasibility="medium",
                        estimated_cost="€25M - €40M",
                        timeline="5-7 years",
                        cost_if_nothing_done="€60M - €90M",
                    ),
                    PreventionMeasure(
                        problem_id="prob-022",
                        action="Modernize wastewater treatment and industrial monitoring",
                        feasibility="high",
                        estimated_cost="€8M - €12M",
                        timeline="36-48 months",
                        cost_if_nothing_done="€40M - €60M",
                    ),
                ],
                "impacts": [
                    EcosystemImpact(
                        problem_id="prob-021",
                        affected_species=["Italian carp", "European catfish", "Wetland birds", "Riparian vegetation"],
                        habitat_impact="Severe habitat reduction; fish stranding; salt water intrusion from Adriatic; agricultural loss",
                        duration="Long-term (requires sustained rainfall)",
                        recovery_potential="Medium - dependent on climate recovery",
                    ),
                    EcosystemImpact(
                        problem_id="prob-022",
                        affected_species=["Fish community", "Benthic organisms", "Aquatic birds", "Mammals"],
                        habitat_impact="Bioaccumulation of contaminants; fish kills; loss of sensitive species; human health concerns",
                        duration="Medium to long-term (3-5 years with treatment)",
                        recovery_potential="Medium with infrastructure investment",
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