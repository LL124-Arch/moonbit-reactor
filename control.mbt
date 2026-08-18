///|
/// Reset a controller after a mode change or safety trip.
pub fn controller_reset(_state : ControllerState) -> ControllerState {
  ControllerState::default()
}

///|
/// Execute one discrete PID step with anti-windup by clamping the integral.
pub fn controller_step(
  config : ControllerConfig,
  state : ControllerState,
  setpoint : Double,
  measurement : Double,
  dt : Double,
) -> ControllerStep {
  let error = setpoint - measurement
  let safe_dt = dt.max(1.0e-9)
  let candidate_integral = state.integral + error * safe_dt
  let raw = config.proportional * error +
    config.integral * candidate_integral +
    config.derivative * (error - state.previous_error) / safe_dt
  let output = raw.clamp(min=config.minimum, max=config.maximum)
  let saturated = output != raw
  let integral = if saturated { state.integral } else { candidate_integral }
  { output, state: { integral, previous_error: error, output }, saturated }
}

///|
/// Simulate a controller against a first-order process model.
pub fn simulate_controller(
  config : ControllerConfig,
  setpoint : Double,
  initial_measurement : Double,
  process_gain : Double,
  process_time_constant : Double,
  dt : Double,
  steps : Int,
) -> Array[ControllerStep] {
  let result : Array[ControllerStep] = []
  let mut state = ControllerState::default()
  let mut measurement = initial_measurement
  let time_constant = process_time_constant.max(1.0e-9)
  for _ in 0..<steps.max(0) {
    let step = controller_step(config, state, setpoint, measurement, dt)
    result.push(step)
    state = step.state
    measurement = measurement +
      dt / time_constant * (process_gain * step.output - measurement)
  }
  result
}

///|
/// The maximum absolute tracking error in a controller trace.
pub fn controller_peak_error(
  trace : ArrayView[ControllerStep],
  setpoint : Double,
) -> Double {
  trace.fold(init=0.0, fn(acc, step) { acc.max((setpoint - step.output).abs()) })
}

///|
/// A smooth actuator map that avoids negative heat-removal commands.
pub fn bounded_actuator(
  value : Double,
  minimum : Double,
  maximum : Double,
) -> Double {
  value.clamp(min=minimum.min(maximum), max=maximum.max(minimum))
}

///|
/// Convert a temperature error into a bounded jacket duty cycle.
pub fn jacket_duty(
  target_temperature : Double,
  reactor_temperature : Double,
  coolant_temperature : Double,
  gain : Double,
) -> Double {
  let available = (reactor_temperature - coolant_temperature).max(1.0e-9)
  bounded_actuator(
    gain.max(0.0) * (reactor_temperature - target_temperature) / available,
    0.0,
    1.0,
  )
}

///|
/// Estimate heat removal from a bounded jacket duty cycle.
pub fn jacket_heat_removal(
  exchange : HeatExchange,
  reactor_temperature : Double,
  target_temperature : Double,
  gain : Double,
) -> Double {
  let duty = jacket_duty(
    target_temperature,
    reactor_temperature,
    exchange.coolant_temperature,
    gain,
  )
  exchange.ua.max(0.0) *
  duty *
  (reactor_temperature - exchange.coolant_temperature).max(0.0)
}

///|
/// Check the standard monotonicity and boundedness invariants of a trace.
pub fn controller_trace_is_bounded(
  trace : ArrayView[ControllerStep],
  config : ControllerConfig,
) -> Bool {
  for step in trace {
    if step.output < config.minimum || step.output > config.maximum {
      return false
    }
  }
  true
}
