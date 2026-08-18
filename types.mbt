///|
pub(all) enum ReactorKind {
  Cstr
  Pfr
  Batch
} derive(Debug, Eq, ToJson)

///|
pub(all) enum ThermalMode {
  Isothermal
  Adiabatic
  NonIsothermal
} derive(Debug, Eq, ToJson)

///|
pub(all) enum KineticOrder {
  Zero
  First
  Second
} derive(Debug, Eq, ToJson)

///|
pub(all) struct Reaction {
  name : String
  order : KineticOrder
  k_ref : Double
  activation_energy : Double
  reference_temperature : Double
  reaction_enthalpy : Double
} derive(Debug, ToJson)

///|
pub(all) struct Feed {
  concentration : Double
  volumetric_flow : Double
  temperature : Double
  heat_capacity_flow : Double
} derive(Debug, ToJson)

///|
pub(all) struct HeatExchange {
  ua : Double
  coolant_temperature : Double
} derive(Debug, ToJson)

///|
pub(all) struct DesignPoint {
  kind : ReactorKind
  thermal_mode : ThermalMode
  volume : Double
  residence_time : Double
  conversion : Double
  outlet_concentration : Double
  outlet_temperature : Double
  heat_removed : Double
  rate_at_outlet : Double
} derive(Debug, ToJson)

///|
pub(all) struct SolverSettings {
  tolerance : Double
  max_iterations : Int
} derive(Debug, ToJson)

///|
pub(all) struct BracketResult {
  root : Double
  residual : Double
  iterations : Int
  converged : Bool
} derive(Debug, ToJson)

///|
pub(all) enum SolverStatus {
  Converged
  BracketFailure
  IterationLimit
  InvalidRange
} derive(Debug, Eq, ToJson)

///|
pub(all) struct SolverReport {
  status : SolverStatus
  root : Double
  residual : Double
  iterations : Int
} derive(Debug, ToJson)

///|
pub(all) struct ReversibleFirstOrder {
  forward_rate : Double
  reverse_rate : Double
  equilibrium_concentration : Double
} derive(Debug, ToJson)

///|
pub(all) struct SeriesReactionResult {
  intermediate_concentration : Double
  product_concentration : Double
  intermediate_selectivity : Double
} derive(Debug, ToJson)

///|
pub(all) struct ParallelReactionResult {
  product_a_rate : Double
  product_b_rate : Double
  product_a_selectivity : Double
  product_b_selectivity : Double
} derive(Debug, ToJson)

///|
pub(all) enum BenchmarkCategory {
  Analytical
  LiteratureKinetics
  MeasuredProperty
  Screening
} derive(Debug, Eq, ToJson)

///|
pub(all) struct BenchmarkCase {
  id : String
  title : String
  category : BenchmarkCategory
  source : String
  source_url : String
  units : String
  assumptions : String
  expected : Double
  tolerance : Double
} derive(Debug, ToJson)

///|
pub(all) struct BenchmarkResult {
  id : String
  expected : Double
  actual : Double
  absolute_error : Double
  tolerance : Double
  passed : Bool
  source_url : String
} derive(Debug, ToJson)

///|
pub(all) struct ReactorSweepPoint {
  volume : Double
  conversion : Double
  outlet_temperature : Double
} derive(Debug, ToJson)

///|
pub(all) struct SafetyBoundary {
  max_safe_volume : Double
  max_safe_residence_time : Double
  hot_spot_temperature : Double
  conversion_at_boundary : Double
  limited_by_temperature : Bool
} derive(Debug, ToJson)

///|
/// A numerical integration result with an explicit error estimate.
pub(all) struct IntegrationResult {
  value : Double
  estimated_error : Double
  evaluations : Int
  converged : Bool
} derive(Debug, ToJson)

///|
/// A sampled axial or temporal reactor state.
pub(all) struct ProfilePoint {
  position : Double
  time : Double
  conversion : Double
  concentration : Double
  temperature : Double
  rate : Double
} derive(Debug, ToJson)

///|
/// Local finite-difference sensitivities of a design point.
pub(all) struct SensitivityReport {
  conversion_wrt_volume : Double
  conversion_wrt_rate_constant : Double
  conversion_wrt_temperature : Double
  temperature_wrt_volume : Double
  volume_wrt_target_conversion : Double
} derive(Debug, ToJson)

///|
/// A conservative interval for a screening calculation.
pub(all) struct ConversionInterval {
  minimum_conversion : Double
  maximum_conversion : Double
  nominal_conversion : Double
  minimum_temperature : Double
  maximum_temperature : Double
} derive(Debug, ToJson)

///|
/// Summary statistics for deterministic uncertainty samples.
pub(all) struct UncertaintySummary {
  samples : Int
  minimum : Double
  maximum : Double
  mean : Double
  standard_deviation : Double
  p05 : Double
  p50 : Double
  p95 : Double
} derive(Debug, ToJson)

///|
/// PID gains and actuator limits.
pub(all) struct ControllerConfig {
  proportional : Double
  integral : Double
  derivative : Double
  minimum : Double
  maximum : Double
} derive(Debug, ToJson)

///|
/// Persistent state for a discrete controller.
pub(all) struct ControllerState {
  integral : Double
  previous_error : Double
  output : Double
} derive(Debug, ToJson)

///|
/// The controller output and updated state.
pub(all) struct ControllerStep {
  output : Double
  state : ControllerState
  saturated : Bool
} derive(Debug, ToJson)

///|
/// Economic assumptions for early-stage design screening.
pub(all) struct CostAssumptions {
  annual_hours : Double
  electricity_price : Double
  vessel_cost_per_volume : Double
  pump_cost_per_flow : Double
  maintenance_fraction : Double
} derive(Debug, ToJson)

///|
/// A transparent annualized cost estimate.
pub(all) struct CostEstimate {
  capital : Double
  utilities : Double
  maintenance : Double
  total : Double
} derive(Debug, ToJson)

///|
/// A design point annotated with feasibility checks.
pub(all) struct EnvelopePoint {
  volume : Double
  conversion : Double
  temperature : Double
  feasible : Bool
  reason : String
} derive(Debug, ToJson)

///|
/// Per-stage and aggregate results for a train.
pub(all) struct TrainResult {
  stages : Array[DesignPoint]
  final_conversion : Double
  total_volume : Double
  total_residence_time : Double
} derive(Debug, ToJson)

///|
/// A reproducible input perturbation used by sensitivity analysis.
pub(all) struct Perturbation {
  rate_multiplier : Double
  temperature_offset : Double
  flow_multiplier : Double
} derive(Debug, ToJson)

///|
/// A single design objective used by screening optimizers.
pub(all) struct ObjectiveScore {
  volume : Double
  conversion : Double
  temperature : Double
  score : Double
  feasible : Bool
} derive(Debug, ToJson)

///|
pub fn Reaction::new(
  name~ : String,
  order~ : KineticOrder,
  k_ref~ : Double,
  activation_energy? : Double = 0.0,
  reference_temperature? : Double = 298.15,
  reaction_enthalpy? : Double = 0.0,
) -> Reaction {
  {
    name,
    order,
    k_ref,
    activation_energy,
    reference_temperature,
    reaction_enthalpy,
  }
}

///|
pub fn Feed::new(
  concentration~ : Double,
  volumetric_flow~ : Double,
  temperature~ : Double,
  heat_capacity_flow? : Double = 1.0,
) -> Feed {
  { concentration, volumetric_flow, temperature, heat_capacity_flow }
}

///|
pub fn HeatExchange::new(
  ua~ : Double,
  coolant_temperature~ : Double,
) -> HeatExchange {
  { ua, coolant_temperature }
}

///|
/// Construct conservative controller gains and actuator limits.
pub fn ControllerConfig::new(
  proportional~ : Double,
  integral~ : Double,
  derivative~ : Double,
  minimum~ : Double,
  maximum~ : Double,
) -> ControllerConfig {
  {
    proportional: proportional.max(0.0),
    integral: integral.max(0.0),
    derivative: derivative.max(0.0),
    minimum: minimum.min(maximum),
    maximum: maximum.max(minimum),
  }
}

///|
pub fn ControllerState::default() -> ControllerState {
  { integral: 0.0, previous_error: 0.0, output: 0.0 }
}

///|
pub fn ControllerConfig::validate(self : ControllerConfig) -> Bool {
  self.minimum <= self.maximum &&
  self.proportional >= 0.0 &&
  self.integral >= 0.0 &&
  self.derivative >= 0.0
}

///|
pub fn CostAssumptions::default() -> CostAssumptions {
  {
    annual_hours: 8000.0,
    electricity_price: 0.12,
    vessel_cost_per_volume: 1200.0,
    pump_cost_per_flow: 80.0,
    maintenance_fraction: 0.06,
  }
}

///|
pub fn SolverSettings::default() -> SolverSettings {
  { tolerance: 1.0e-8, max_iterations: 80 }
}

///|
pub fn SolverSettings::loose() -> SolverSettings {
  { tolerance: 1.0e-6, max_iterations: 48 }
}

///|
pub fn ReactorKind::to_string(kind : ReactorKind) -> String {
  match kind {
    Cstr => "CSTR"
    Pfr => "PFR"
    Batch => "Batch"
  }
}

///|
pub fn ThermalMode::to_string(mode : ThermalMode) -> String {
  match mode {
    Isothermal => "isothermal"
    Adiabatic => "adiabatic"
    NonIsothermal => "non-isothermal"
  }
}

///|
pub fn KineticOrder::to_string(order : KineticOrder) -> String {
  match order {
    Zero => "zero-order"
    First => "first-order"
    Second => "second-order"
  }
}
