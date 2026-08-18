///|
/// Batch conversion at a sequence of times.
pub fn batch_conversion_curve(
  reaction : Reaction,
  feed : Feed,
  times : ArrayView[Double],
) -> Array[Double] {
  times.map(fn(time) { batch_conversion_isothermal(reaction, feed, time) })
}

///|
/// Batch concentration at a sequence of times.
pub fn batch_concentration_curve(
  reaction : Reaction,
  feed : Feed,
  times : ArrayView[Double],
) -> Array[Double] {
  batch_conversion_curve(reaction, feed, times).map(fn(conversion) {
    concentration_from_conversion(feed, conversion)
  })
}

///|
/// Batch rate at a sequence of times.
pub fn batch_rate_curve(
  reaction : Reaction,
  feed : Feed,
  times : ArrayView[Double],
) -> Array[Double] {
  batch_concentration_curve(reaction, feed, times).map(fn(concentration) {
    reaction.rate(concentration, feed.temperature)
  })
}

///|
/// Find the first time at which a batch conversion target is reached.
pub fn batch_time_for_target(
  reaction : Reaction,
  feed : Feed,
  target : Double,
  maximum_time : Double,
  points : Int,
) -> Double? {
  let times = linspace(0.0, maximum_time.max(0.0), points.max(1))
  for time in times {
    if batch_conversion_isothermal(reaction, feed, time) >=
      clamp_conversion(target) {
      return Some(time)
    }
  }
  None
}

///|
/// Average batch conversion over a time window.
pub fn average_batch_conversion(
  reaction : Reaction,
  feed : Feed,
  duration : Double,
  points : Int,
) -> Double {
  let values = batch_conversion_curve(
    reaction,
    feed,
    linspace(0.0, duration.max(0.0), points.max(2)),
  )
  if values.length() == 0 {
    0.0
  } else {
    values.fold(init=0.0, fn(acc, value) { acc + value }) /
    Double::from_int(values.length())
  }
}

///|
/// Batch productivity at a selected cycle time.
pub fn batch_productivity(
  feed : Feed,
  conversion : Double,
  cycle_time : Double,
  cleaning_time : Double,
) -> Double {
  feed.concentration.max(0.0) *
  clamp_conversion(conversion) /
  (cycle_time.max(0.0) + cleaning_time.max(0.0)).max(1.0e-12)
}

///|
/// Optimize batch cycle time on a regular grid.
pub fn optimize_batch_cycle(
  reaction : Reaction,
  feed : Feed,
  maximum_time : Double,
  cleaning_time : Double,
  points : Int,
) -> ObjectiveScore? {
  let mut best : ObjectiveScore? = None
  for time in linspace(0.0, maximum_time.max(0.0), points.max(1)) {
    let point = design_batch(reaction, feed, time)
    let score = batch_productivity(feed, point.conversion, time, cleaning_time)
    let candidate : ObjectiveScore = {
      volume: time,
      conversion: point.conversion,
      temperature: point.outlet_temperature,
      score,
      feasible: true,
    }
    match best {
      None => best = Some(candidate)
      Some(current) => if score > current.score { best = Some(candidate) }
    }
  }
  best
}

///|
/// Batch conversion gain between two times.
pub fn batch_conversion_gain(
  reaction : Reaction,
  feed : Feed,
  first_time : Double,
  second_time : Double,
) -> Double {
  batch_conversion_isothermal(reaction, feed, second_time) -
  batch_conversion_isothermal(reaction, feed, first_time)
}

///|
/// Check monotonicity of a batch curve.
pub fn batch_curve_is_monotone(values : ArrayView[Double]) -> Bool {
  for i = 1; i < values.length(); i = i + 1 {
    if values[i] + 1.0e-10 < values[i - 1] {
      return false
    }
  }
  true
}

///|
/// CSTR conversion over a sequence of volumes.
pub fn cstr_conversion_curve(
  reaction : Reaction,
  feed : Feed,
  volumes : ArrayView[Double],
) -> Array[Double] {
  volumes.map(fn(volume) { cstr_conversion_isothermal(reaction, feed, volume) })
}

///|
/// PFR conversion over a sequence of volumes.
pub fn pfr_conversion_curve(
  reaction : Reaction,
  feed : Feed,
  volumes : ArrayView[Double],
) -> Array[Double] {
  volumes.map(fn(volume) { pfr_conversion_isothermal(reaction, feed, volume) })
}

///|
/// Compare CSTR and PFR curves at equal volumes.
pub fn compare_reactor_curves(
  reaction : Reaction,
  feed : Feed,
  volumes : ArrayView[Double],
) -> Array[(Double, Double, Double)] {
  let cstr = cstr_conversion_curve(reaction, feed, volumes)
  let pfr = pfr_conversion_curve(reaction, feed, volumes)
  let result : Array[(Double, Double, Double)] = []
  for i in 0..<volumes.length().min(cstr.length()).min(pfr.length()) {
    result.push((volumes[i], cstr[i], pfr[i]))
  }
  result
}

///|
/// Average advantage of a PFR curve over a CSTR curve.
pub fn average_pfr_advantage(
  curve : ArrayView[(Double, Double, Double)],
) -> Double {
  if curve.length() == 0 {
    0.0
  } else {
    curve.fold(init=0.0, fn(acc, point) { acc + point.2 - point.1 }) /
    Double::from_int(curve.length())
  }
}

///|
/// Select the smallest volume meeting a target on a curve.
pub fn curve_volume_for_target(
  curve : ArrayView[(Double, Double, Double)],
  target : Double,
  use_pfr : Bool,
) -> Double? {
  for point in curve {
    if (if use_pfr { point.2 } else { point.1 }) >= clamp_conversion(target) {
      return Some(point.0)
    }
  }
  None
}

///|
/// Integrate a conversion curve with respect to volume.
pub fn conversion_volume_area(
  curve : ArrayView[(Double, Double, Double)],
  use_pfr : Bool,
) -> Double {
  if curve.length() < 2 {
    0.0
  } else {
    for i = 1, area = 0.0; i < curve.length(); i = i + 1 {
      let left = if use_pfr { curve[i - 1].2 } else { curve[i - 1].1 }
      let right = if use_pfr { curve[i].2 } else { curve[i].1 }
      continue i + 1,
        area + (curve[i].0 - curve[i - 1].0) * (left + right) / 2.0
    } nobreak {
      area
    }
  }
}

///|
/// A conservative batch design window.
pub fn batch_design_window(
  reaction : Reaction,
  feed : Feed,
  minimum_conversion : Double,
  maximum_temperature : Double,
  maximum_time : Double,
  points : Int,
) -> Array[EnvelopePoint] {
  let result : Array[EnvelopePoint] = []
  for time in linspace(0.0, maximum_time.max(0.0), points.max(1)) {
    let point = design_batch(reaction, feed, time)
    let conversion_ok = point.conversion >= clamp_conversion(minimum_conversion)
    let temperature_ok = point.outlet_temperature <= maximum_temperature
    result.push({
      volume: time * feed.volumetric_flow,
      conversion: point.conversion,
      temperature: point.outlet_temperature,
      feasible: conversion_ok && temperature_ok,
      reason: if conversion_ok && temperature_ok {
        "feasible"
      } else {
        "outside limits"
      },
    })
  }
  result
}
