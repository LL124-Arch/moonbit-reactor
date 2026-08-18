///|
/// Composite Simpson quadrature for a fixed, reproducible grid.
pub fn integrate_simpson(
  lower : Double,
  upper : Double,
  steps : Int,
  f : (Double) -> Double,
) -> Double {
  let n = if steps < 2 { 2 } else if steps % 2 == 0 { steps } else { steps + 1 }
  let h = (upper - lower) / Double::from_int(n)
  let middle = for i = 1, odd = 0.0, even = 0.0; i < n; i = i + 1 {
    let value = f(lower + Double::from_int(i) * h)
    if i % 2 == 0 {
      continue i + 1, odd, even + value
    } else {
      continue i + 1, odd + value, even
    }
  } nobreak {
    (odd, even)
  }
  (f(lower) + f(upper) + 4.0 * middle.0 + 2.0 * middle.1) * h / 3.0
}

///|
/// One adaptive Simpson refinement with a local error estimate.
fn adaptive_panel(
  a : Double,
  b : Double,
  fa : Double,
  fm : Double,
  fb : Double,
  whole : Double,
  tolerance : Double,
  depth : Int,
  f : (Double) -> Double,
) -> (Double, Double, Int, Bool) {
  let left_mid = (a + (a + b) / 2.0) / 2.0
  let right_mid = ((a + b) / 2.0 + b) / 2.0
  let fl = f(left_mid)
  let fr = f(right_mid)
  let half = (a + b) / 2.0
  let left = (half - a) / 6.0 * (fa + 4.0 * fl + fm)
  let right = (b - half) / 6.0 * (fm + 4.0 * fr + fb)
  let refined = left + right
  let error = (refined - whole).abs() / 15.0
  if depth <= 0 || error <= tolerance {
    (refined + (refined - whole) / 15.0, error, 2, depth > 0)
  } else {
    let left_result = adaptive_panel(
      a,
      half,
      fa,
      fl,
      fm,
      left,
      tolerance / 2.0,
      depth - 1,
      f,
    )
    let right_result = adaptive_panel(
      half,
      b,
      fm,
      fr,
      fb,
      right,
      tolerance / 2.0,
      depth - 1,
      f,
    )
    (
      left_result.0 + right_result.0,
      left_result.1 + right_result.1,
      left_result.2 + right_result.2 + 2,
      left_result.3 && right_result.3,
    )
  }
}

///|
/// Adaptive quadrature that preserves the sign of reversed intervals.
pub fn integrate_adaptive(
  lower : Double,
  upper : Double,
  f : (Double) -> Double,
  tolerance? : Double = 1.0e-8,
  max_depth? : Int = 16,
) -> IntegrationResult {
  if lower == upper {
    { value: 0.0, estimated_error: 0.0, evaluations: 0, converged: true }
  } else if lower > upper {
    let result = integrate_adaptive(upper, lower, f, tolerance~, max_depth~)
    { ..result, value: -result.value }
  } else {
    let midpoint = (lower + upper) / 2.0
    let fa = f(lower)
    let fm = f(midpoint)
    let fb = f(upper)
    let whole = (upper - lower) / 6.0 * (fa + 4.0 * fm + fb)
    let result = adaptive_panel(
      lower,
      upper,
      fa,
      fm,
      fb,
      whole,
      tolerance.max(1.0e-14),
      max_depth.max(1),
      f,
    )
    {
      value: result.0,
      estimated_error: result.1,
      evaluations: result.2 + 3,
      converged: result.3,
    }
  }
}

///|
/// A single fourth-order Runge-Kutta step.
pub fn rk4_step(
  time : Double,
  state : Double,
  step : Double,
  derivative : (Double, Double) -> Double,
) -> Double {
  let k1 = derivative(time, state)
  let k2 = derivative(time + step / 2.0, state + step * k1 / 2.0)
  let k3 = derivative(time + step / 2.0, state + step * k2 / 2.0)
  let k4 = derivative(time + step, state + step * k3)
  state + step * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0
}

///|
/// Integrate a scalar ODE with fixed-step RK4.
pub fn integrate_rk4(
  initial : Double,
  start : Double,
  end : Double,
  steps : Int,
  derivative : (Double, Double) -> Double,
) -> Double {
  let n = steps.max(1)
  let step = (end - start) / Double::from_int(n)
  for i = 0, value = initial; i < n; i = i + 1 {
    let time = start + Double::from_int(i) * step
    continue i + 1, rk4_step(time, value, step, derivative)
  } nobreak {
    value
  }
}

///|
/// Estimate a derivative using a scale-aware central difference.
pub fn central_difference(
  x : Double,
  f : (Double) -> Double,
  step? : Double = 1.0e-5,
) -> Double {
  let h = step.max(1.0e-12) * (1.0 + x.abs())
  (f(x + h) - f(x - h)) / (2.0 * h)
}

///|
/// Return a Richardson-improved derivative estimate.
pub fn richardson_derivative(
  x : Double,
  f : (Double) -> Double,
  step? : Double = 1.0e-4,
) -> Double {
  let coarse = central_difference(x, f, step~)
  let fine = central_difference(x, f, step=step / 2.0)
  fine + (fine - coarse) / 3.0
}
