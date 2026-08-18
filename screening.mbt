///|
/// Estimate annualized cost for an early design point.
pub fn estimate_annual_cost(
  point : DesignPoint,
  assumptions : CostAssumptions,
) -> CostEstimate {
  let capital = point.volume.max(0.0) *
    assumptions.vessel_cost_per_volume.max(0.0)
  let pumping = point.volume.max(0.0) * assumptions.pump_cost_per_flow.max(0.0)
  let thermal = point.heat_removed.abs() *
    assumptions.annual_hours.max(0.0) *
    assumptions.electricity_price.max(0.0) /
    1000.0
  let utilities = pumping + thermal
  let maintenance = capital * assumptions.maintenance_fraction.max(0.0)
  { capital, utilities, maintenance, total: capital + utilities + maintenance }
}

///|
/// Compare the annualized cost of two design points.
pub fn cost_savings(
  reference : CostEstimate,
  candidate : CostEstimate,
) -> Double {
  reference.total - candidate.total
}

///|
/// Return the cost per unit of converted feed, with a safe zero boundary.
pub fn cost_per_conversion(cost : CostEstimate, point : DesignPoint) -> Double {
  if point.conversion <= 1.0e-12 {
    cost.total / 1.0e-12
  } else {
    cost.total / point.conversion
  }
}

///|
/// Evaluate a volume grid against conversion and temperature limits.
pub fn design_envelope(
  reaction : Reaction,
  feed : Feed,
  minimum_volume : Double,
  maximum_volume : Double,
  steps : Int,
  minimum_conversion : Double,
  maximum_temperature : Double,
) -> Array[EnvelopePoint] {
  let count = steps.max(0)
  let result : Array[EnvelopePoint] = []
  for i in 0..<=count {
    let fraction = if count == 0 {
      0.0
    } else {
      Double::from_int(i) / Double::from_int(count)
    }
    let volume = minimum_volume + (maximum_volume - minimum_volume) * fraction
    let point = design_pfr(reaction, feed, volume)
    let conversion_ok = point.conversion >= minimum_conversion
    let temperature_ok = point.outlet_temperature <= maximum_temperature
    let reason = if conversion_ok && temperature_ok {
      "feasible"
    } else if !conversion_ok && !temperature_ok {
      "conversion and temperature limits"
    } else if !conversion_ok {
      "conversion limit"
    } else {
      "temperature limit"
    }
    result.push({
      volume,
      conversion: point.conversion,
      temperature: point.outlet_temperature,
      feasible: conversion_ok && temperature_ok,
      reason,
    })
  }
  result
}

///|
/// Select the feasible point with the lowest volume.
pub fn minimum_feasible_volume(
  points : ArrayView[EnvelopePoint],
) -> EnvelopePoint? {
  let mut best : EnvelopePoint? = None
  for point in points {
    if point.feasible {
      match best {
        None => best = Some(point)
        Some(current) => if point.volume < current.volume { best = Some(point) }
      }
    }
  }
  best
}

///|
/// Score a candidate using conversion benefit and volume penalty.
pub fn score_design(
  point : DesignPoint,
  conversion_weight : Double,
  volume_weight : Double,
  temperature_limit : Double,
) -> ObjectiveScore {
  let feasible = point.outlet_temperature <= temperature_limit
  let penalty = if feasible { 0.0 } else { 1.0e6 }
  let score = conversion_weight.max(0.0) * point.conversion -
    volume_weight.max(0.0) * point.volume -
    penalty
  {
    volume: point.volume,
    conversion: point.conversion,
    temperature: point.outlet_temperature,
    score,
    feasible,
  }
}

///|
/// Enumerate a coarse, deterministic design objective surface.
pub fn objective_surface(
  reaction : Reaction,
  feed : Feed,
  volumes : ArrayView[Double],
  conversion_weight : Double,
  volume_weight : Double,
  temperature_limit : Double,
) -> Array[ObjectiveScore] {
  let result : Array[ObjectiveScore] = []
  for volume in volumes {
    result.push(
      score_design(
        design_pfr(reaction, feed, volume),
        conversion_weight,
        volume_weight,
        temperature_limit,
      ),
    )
  }
  result
}

///|
/// Find the highest-scoring candidate, preserving the first tie.
pub fn best_objective(scores : ArrayView[ObjectiveScore]) -> ObjectiveScore? {
  let mut best : ObjectiveScore? = None
  for score in scores {
    match best {
      None => best = Some(score)
      Some(current) => if score.score > current.score { best = Some(score) }
    }
  }
  best
}
