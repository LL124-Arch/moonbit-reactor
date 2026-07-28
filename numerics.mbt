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
  let fl = f(lower)
  let fu = f(upper)
  if fl == 0.0 {
    { root: lower, residual: 0.0, iterations: 0, converged: true }
  } else if fu == 0.0 {
    { root: upper, residual: 0.0, iterations: 0, converged: true }
  } else if fl * fu > 0.0 {
    let mid = (lower + upper) / 2.0
    { root: mid, residual: f(mid), iterations: 0, converged: false }
  } else {
    for lo = lower, hi = upper, flo = fl, i = 0; i < settings.max_iterations; {
      let mid = (lo + hi) / 2.0
      let fm = f(mid)
      if fm.abs() <= settings.tolerance || (hi - lo).abs() <= settings.tolerance {
        break { root: mid, residual: fm, iterations: i + 1, converged: true }
      }
      if flo * fm <= 0.0 {
        continue lo, mid, flo, i + 1
      } else {
        continue mid, hi, fm, i + 1
      }
    } nobreak {
      let mid = (lower + upper) / 2.0
      {
        root: mid,
        residual: f(mid),
        iterations: settings.max_iterations,
        converged: false,
      }
    }
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
