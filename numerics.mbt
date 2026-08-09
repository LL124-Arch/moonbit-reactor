///|
pub fn absolute(x : Double) -> Double {
  x.abs()
}

///|
pub fn nearly_equal(
  a : Double,
  b : Double,
  tolerance? : Double = 1.0e-8,
) -> Bool {
  (a - b).abs() <= tolerance
}

///|
pub fn bisect(
  lower : Double,
  upper : Double,
  f : (Double) -> Double,
  settings? : SolverSettings = SolverSettings::default(),
) -> BracketResult {
  let report = bisect_report(lower, upper, f, settings~)
  {
    root: report.root,
    residual: report.residual,
    iterations: report.iterations,
    converged: report.status == Converged,
  }
}

///|
pub fn integrate_trapezoid(
  lower : Double,
  upper : Double,
  steps : Int,
  f : (Double) -> Double,
) -> Double {
  let n = steps.max(1)
  let h = (upper - lower) / Double::from_int(n)
  let middle = for i = 1, acc = 0.0; i < n; i = i + 1 {
    continue i + 1, acc + f(lower + Double::from_int(i) * h)
  } nobreak {
    acc
  }
  (f(lower) + f(upper) + 2.0 * middle) * h / 2.0
}

///|
pub fn euler_integrate(
  initial : Double,
  dt : Double,
  steps : Int,
  derivative : (Double, Double) -> Double,
) -> Double {
  for i = 0, y = initial; i < steps; i = i + 1 {
    let t = Double::from_int(i) * dt
    continue i + 1, y + dt * derivative(t, y)
  } nobreak {
    y
  }
}
