///|
fn finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
pub fn bisect_report(
  lower : Double,
  upper : Double,
  f : (Double) -> Double,
  settings? : SolverSettings = SolverSettings::default(),
) -> SolverReport {
  if !finite(lower) || !finite(upper) || lower > upper {
    { status: InvalidRange, root: lower, residual: 0.0, iterations: 0 }
  } else {
    let fl = f(lower)
    let fu = f(upper)
    if !finite(fl) || !finite(fu) {
      { status: InvalidRange, root: lower, residual: fl, iterations: 0 }
    } else if fl == 0.0 {
      { status: Converged, root: lower, residual: fl, iterations: 0 }
    } else if fu == 0.0 {
      { status: Converged, root: upper, residual: fu, iterations: 0 }
    } else if fl * fu > 0.0 {
      let mid = (lower + upper) / 2.0
      { status: BracketFailure, root: mid, residual: f(mid), iterations: 0 }
    } else {
      for lo = lower, hi = upper, flo = fl, i = 0; i < settings.max_iterations; {
        let mid = (lo + hi) / 2.0
        let fm = f(mid)
        if !finite(fm) {
          break {
            status: InvalidRange,
            root: mid,
            residual: fm,
            iterations: i + 1,
          }
        }
        if fm.abs() <= settings.tolerance ||
          (hi - lo).abs() <= settings.tolerance {
          break {
            status: Converged,
            root: mid,
            residual: fm,
            iterations: i + 1,
          }
        }
        if flo * fm <= 0.0 {
          continue lo, mid, flo, i + 1
        } else {
          continue mid, hi, fm, i + 1
        }
      } nobreak {
        let mid = (lower + upper) / 2.0
        {
          status: IterationLimit,
          root: mid,
          residual: f(mid),
          iterations: settings.max_iterations,
        }
      }
    }
  }
}

///|
pub fn integrate_trapezoid_report(
  lower : Double,
  upper : Double,
  steps : Int,
  f : (Double) -> Double,
) -> SolverReport {
  if steps <= 0 || !finite(lower) || !finite(upper) {
    { status: InvalidRange, root: 0.0, residual: 0.0, iterations: 0 }
  } else {
    {
      status: Converged,
      root: integrate_trapezoid(lower, upper, steps, f),
      residual: 0.0,
      iterations: steps,
    }
  }
}
