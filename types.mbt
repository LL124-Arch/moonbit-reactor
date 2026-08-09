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
