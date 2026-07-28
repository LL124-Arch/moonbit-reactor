///|
pub(all) struct SearchRange {
  min : Double
  max : Double
  steps : Int
} derive(Debug, ToJson)

///|
pub(all) struct OptimizationResult {
  volume : Double
  conversion : Double
  temperature : Double
  objective : Double
  feasible : Bool
} derive(Debug, ToJson)

///|
pub fn SearchRange::new(
  min~ : Double,
  max~ : Double,
  steps~ : Int,
) -> SearchRange {
  { min, max, steps: steps.max(2) }
}

///|
pub fn maximize_conversion_under_temperature(
  reaction : Reaction,
  feed : Feed,
  range : SearchRange,
  max_temperature : Double,
  thermal_mode? : ThermalMode = Adiabatic,
  exchange? : HeatExchange,
) -> OptimizationResult {
  scan_volume_range(range, fn(v) {
    let point = match exchange {
      Some(hx) => design_cstr(reaction, feed, v, thermal_mode~, exchange=hx)
      None => design_cstr(reaction, feed, v, thermal_mode~)
    }
    if point.outlet_temperature <= max_temperature {
      {
        volume: v,
        conversion: point.conversion,
        temperature: point.outlet_temperature,
        objective: point.conversion,
        feasible: true,
      }
    } else {
      {
        volume: v,
        conversion: point.conversion,
        temperature: point.outlet_temperature,
        objective: -1.0,
        feasible: false,
      }
    }
  })
}

///|
pub fn minimize_volume_for_conversion(
  reaction : Reaction,
  feed : Feed,
  range : SearchRange,
  target_conversion : Double,
  kind? : ReactorKind = Pfr,
) -> OptimizationResult {
  scan_volume_range(range, fn(v) {
    let point = match kind {
      Cstr => design_cstr(reaction, feed, v)
      Pfr => design_pfr(reaction, feed, v)
      Batch =>
        design_batch(reaction, feed, v / feed.volumetric_flow.max(1.0e-12))
    }
    if point.conversion >= target_conversion {
      {
        volume: v,
        conversion: point.conversion,
        temperature: point.outlet_temperature,
        objective: -v,
        feasible: true,
      }
    } else {
      {
        volume: v,
        conversion: point.conversion,
        temperature: point.outlet_temperature,
        objective: -1.0e99,
        feasible: false,
      }
    }
  })
}

///|
fn scan_volume_range(
  range : SearchRange,
  score : (Double) -> OptimizationResult,
) -> OptimizationResult {
  let n = range.steps.max(2)
  for i = 0, best = {
          volume: range.min,
          conversion: 0.0,
          temperature: 0.0,
          objective: -1.0e99,
          feasible: false,
        }
      i < n
      i = i + 1 {
    let v = range.min +
      (range.max - range.min) * Double::from_int(i) / Double::from_int(n - 1)
    let candidate = score(v)
    if candidate.feasible &&
      (!best.feasible || candidate.objective > best.objective) {
      continue i + 1, candidate
    } else {
      continue i + 1, best
    }
  } nobreak {
    best
  }
}
