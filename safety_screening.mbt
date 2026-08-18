///|
/// A thermal runaway screening result.
pub(all) struct ThermalScreening {
  inlet_temperature : Double
  outlet_temperature : Double
  maximum_temperature : Double
  margin : Double
  safe : Bool
} derive(Debug, ToJson)

///|
/// Screen one design point against a maximum temperature.
pub fn screen_temperature(
  point : DesignPoint,
  maximum_temperature : Double,
) -> ThermalScreening {
  {
    inlet_temperature: point.outlet_temperature,
    outlet_temperature: point.outlet_temperature,
    maximum_temperature,
    margin: maximum_temperature - point.outlet_temperature,
    safe: point.outlet_temperature <= maximum_temperature,
  }
}

///|
/// Screen a scenario against conversion and temperature limits.
pub fn screen_scenario(
  scenario : OperatingScenario,
  minimum_conversion : Double,
  maximum_temperature : Double,
) -> Bool {
  let point = evaluate_scenario(scenario)
  point.conversion >= clamp_conversion(minimum_conversion) &&
  point.outlet_temperature <= maximum_temperature
}

///|
/// Determine the largest safe point in a sweep.
pub fn last_safe_sweep_point(
  points : ArrayView[ReactorSweepPoint],
  maximum_temperature : Double,
) -> ReactorSweepPoint? {
  let mut result : ReactorSweepPoint? = None
  for point in points {
    if point.outlet_temperature <= maximum_temperature {
      result = Some(point)
    }
  }
  result
}

///|
/// Find the first unsafe point in a sweep.
pub fn first_unsafe_sweep_point(
  points : ArrayView[ReactorSweepPoint],
  maximum_temperature : Double,
) -> ReactorSweepPoint? {
  for point in points {
    if point.outlet_temperature > maximum_temperature {
      return Some(point)
    }
  }
  None
}

///|
/// Count safe and unsafe points.
pub fn safety_counts(
  points : ArrayView[ReactorSweepPoint],
  maximum_temperature : Double,
) -> (Int, Int) {
  points.fold(init=(0, 0), fn(acc, point) {
    if point.outlet_temperature <= maximum_temperature {
      (acc.0 + 1, acc.1)
    } else {
      (acc.0, acc.1 + 1)
    }
  })
}

///|
/// Maximum temperature margin in a sweep.
pub fn maximum_temperature_margin(
  points : ArrayView[ReactorSweepPoint],
  maximum_temperature : Double,
) -> Double {
  points.fold(init=-1.0e30, fn(acc, point) {
    acc.max(maximum_temperature - point.outlet_temperature)
  })
}

///|
/// Minimum temperature margin in a sweep.
pub fn minimum_temperature_margin(
  points : ArrayView[ReactorSweepPoint],
  maximum_temperature : Double,
) -> Double {
  points.fold(init=1.0e30, fn(acc, point) {
    acc.min(maximum_temperature - point.outlet_temperature)
  })
}

///|
/// A conservative pressure-drop estimate for a pipe segment.
pub fn pressure_drop(
  length : Double,
  diameter : Double,
  density : Double,
  velocity : Double,
  friction_factor : Double,
) -> Double {
  friction_factor.max(0.0) *
  length.max(0.0) /
  diameter.max(1.0e-12) *
  density.max(0.0) *
  velocity.max(0.0) *
  velocity.max(0.0) /
  2.0
}

///|
/// Flow velocity from volumetric flow and diameter.
pub fn flow_velocity(volumetric_flow : Double, diameter : Double) -> Double {
  volumetric_flow.max(0.0) /
  (3.141592653589793 * diameter.max(1.0e-12) * diameter.max(1.0e-12) / 4.0)
}

///|
/// Reynolds number for a pipe screening calculation.
pub fn reynolds_number(
  density : Double,
  velocity : Double,
  diameter : Double,
  viscosity : Double,
) -> Double {
  density.max(0.0) *
  velocity.max(0.0) *
  diameter.max(0.0) /
  viscosity.max(1.0e-12)
}

///|
/// Laminar friction-factor approximation.
pub fn laminar_friction_factor(reynolds : Double) -> Double {
  64.0 / reynolds.max(1.0)
}

///|
/// Blasius friction-factor approximation for turbulent flow.
pub fn blasius_friction_factor(reynolds : Double) -> Double {
  0.3164 / @math.pow(reynolds.max(1.0), 0.25)
}

///|
/// Choose a smooth friction-factor approximation by Reynolds number.
pub fn friction_factor(reynolds : Double) -> Double {
  if reynolds <= 2300.0 {
    laminar_friction_factor(reynolds)
  } else {
    blasius_friction_factor(reynolds)
  }
}

///|
/// Check whether a pipe flow is inside a declared velocity window.
pub fn velocity_window_ok(
  velocity : Double,
  minimum : Double,
  maximum : Double,
) -> Bool {
  velocity >= minimum.min(maximum) && velocity <= maximum.max(minimum)
}

///|
/// Screen a residence time against a minimum and maximum.
pub fn residence_window_ok(
  residence : Double,
  minimum : Double,
  maximum : Double,
) -> Bool {
  residence >= minimum.min(maximum) && residence <= maximum.max(minimum)
}

///|
/// Safety factor between a limit and an observed value.
pub fn safety_factor(limit : Double, observed : Double) -> Double {
  limit.abs() / observed.abs().max(1.0e-12)
}

///|
/// Convert a safety factor to a pass/fail result.
pub fn safety_factor_ok(
  limit : Double,
  observed : Double,
  minimum_factor : Double,
) -> Bool {
  safety_factor(limit, observed) >= minimum_factor
}

///|
/// Check whether a conversion target is too close to the singular limit.
pub fn conversion_target_is_well_conditioned(target : Double) -> Bool {
  target >= 0.0 && target <= 0.99
}

///|
/// Condition number estimate for first-order PFR conversion.
pub fn first_order_condition_number(damkohler : Double) -> Double {
  damkohler.max(0.0) / (1.0 + damkohler.max(0.0))
}

///|
/// Condition number estimate for a bisection interval.
pub fn bracket_condition_number(
  lower : Double,
  upper : Double,
  tolerance : Double,
) -> Double {
  (upper - lower).abs() / tolerance.abs().max(1.0e-12)
}

///|
/// Return a conservative iteration budget for bisection.
pub fn bisection_budget(
  lower : Double,
  upper : Double,
  tolerance : Double,
) -> Int {
  let ratio = bracket_condition_number(lower, upper, tolerance).max(1.0)
  let estimate = natural_log(ratio) / natural_log(2.0).max(1.0e-12)
  estimate.ceil().to_int() + 1
}
