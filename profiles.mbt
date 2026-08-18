///|
/// Build an ideal plug-flow concentration profile.
pub fn pfr_profile(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  points~ : Int,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> Array[ProfilePoint] {
  let count = points.max(1)
  let result : Array[ProfilePoint] = []
  for i in 0..<count {
    let fraction = if count == 1 {
      1.0
    } else {
      Double::from_int(i) / Double::from_int(count - 1)
    }
    let local_volume = volume.max(0.0) * fraction
    let design = match exchange {
      Some(hx) =>
        design_pfr(reaction, feed, local_volume, thermal_mode~, exchange=hx)
      None => design_pfr(reaction, feed, local_volume, thermal_mode~)
    }
    result.push({
      position: fraction,
      time: design.residence_time,
      conversion: design.conversion,
      concentration: design.outlet_concentration,
      temperature: design.outlet_temperature,
      rate: design.rate_at_outlet,
    })
  }
  result
}

///|
/// Build a batch trajectory using RK4 on the conversion state.
pub fn batch_profile(
  reaction : Reaction,
  feed : Feed,
  final_time : Double,
  points~ : Int,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> Array[ProfilePoint] {
  let count = points.max(1)
  let result : Array[ProfilePoint] = []
  for i in 0..<count {
    let fraction = if count == 1 {
      1.0
    } else {
      Double::from_int(i) / Double::from_int(count - 1)
    }
    let time = final_time.max(0.0) * fraction
    let conversion = if thermal_mode == Isothermal {
      batch_conversion_isothermal(reaction, feed, time)
    } else {
      match exchange {
        Some(hx) =>
          design_batch(reaction, feed, time, thermal_mode~, exchange=hx).conversion
        None => design_batch(reaction, feed, time, thermal_mode~).conversion
      }
    }
    let temperature = temperature_for_mode(
      thermal_mode, feed, reaction, conversion, exchange,
    )
    let concentration = concentration_from_conversion(feed, conversion)
    result.push({
      position: fraction,
      time,
      conversion,
      concentration,
      temperature,
      rate: reaction.rate(concentration, temperature),
    })
  }
  result
}

///|
/// Check that a profile never decreases in conversion beyond tolerance.
pub fn profile_is_monotone(profile : ArrayView[ProfilePoint]) -> Bool {
  if profile.length() < 2 {
    true
  } else {
    for i = 1; i < profile.length(); i = i + 1 {
      if profile[i].conversion + 1.0e-10 < profile[i - 1].conversion {
        return false
      }
    }
    true
  }
}

///|
/// Integrate conversion-weighted rate exposure over a profile.
pub fn profile_rate_exposure(profile : ArrayView[ProfilePoint]) -> Double {
  if profile.length() < 2 {
    0.0
  } else {
    for i = 1, total = 0.0; i < profile.length(); i = i + 1 {
      let width = profile[i].position - profile[i - 1].position
      continue i + 1,
        total + width * (profile[i].rate + profile[i - 1].rate) / 2.0
    } nobreak {
      total
    }
  }
}

///|
/// Convert a profile to a stable CSV representation for notebooks.
pub fn profile_to_csv(profile : ArrayView[ProfilePoint]) -> String {
  let output = "position,time,conversion,concentration,temperature,rate\n"
  profile.fold(init=output, fn(acc, point) {
    acc +
    format_double(point.position) +
    "," +
    format_double(point.time) +
    "," +
    format_double(point.conversion) +
    "," +
    format_double(point.concentration) +
    "," +
    format_double(point.temperature) +
    "," +
    format_double(point.rate) +
    "\n"
  })
}

///|
/// Conversion at an arbitrary dimensionless axial coordinate.
pub fn profile_interpolate(
  profile : ArrayView[ProfilePoint],
  position : Double,
) -> ProfilePoint {
  if profile.length() == 0 {
    {
      position: 0.0,
      time: 0.0,
      conversion: 0.0,
      concentration: 0.0,
      temperature: 0.0,
      rate: 0.0,
    }
  } else {
    let p = position.clamp(min=0.0, max=1.0)
    let mut index = 0
    while index + 1 < profile.length() && profile[index + 1].position < p {
      index = index + 1
    }
    if index + 1 >= profile.length() {
      profile[profile.length() - 1]
    } else {
      let left = profile[index]
      let right = profile[index + 1]
      let span = (right.position - left.position).max(1.0e-12)
      let w = (p - left.position) / span
      {
        position: p,
        time: left.time + w * (right.time - left.time),
        conversion: left.conversion + w * (right.conversion - left.conversion),
        concentration: left.concentration +
        w * (right.concentration - left.concentration),
        temperature: left.temperature +
        w * (right.temperature - left.temperature),
        rate: left.rate + w * (right.rate - left.rate),
      }
    }
  }
}
