///|
/// A generic power-law rate evaluation for screening.
pub fn power_law_rate(
  rate_constant : Double,
  concentration : Double,
  order : Double,
) -> Double {
  rate_constant.max(0.0) * @math.pow(concentration.max(0.0), order.max(0.0))
}

///|
/// Zero-order consumption over a bounded time interval.
pub fn zero_order_concentration(
  initial : Double,
  rate_constant : Double,
  time : Double,
) -> Double {
  (initial - rate_constant.max(0.0) * time.max(0.0)).max(0.0)
}

///|
/// First-order concentration decay.
pub fn first_order_concentration(
  initial : Double,
  rate_constant : Double,
  time : Double,
) -> Double {
  initial.max(0.0) * @math.exp(-rate_constant.max(0.0) * time.max(0.0))
}

///|
/// Second-order concentration decay.
pub fn second_order_concentration(
  initial : Double,
  rate_constant : Double,
  time : Double,
) -> Double {
  let c0 = initial.max(0.0)
  c0 / (1.0 + rate_constant.max(0.0) * c0 * time.max(0.0))
}

///|
/// Invert a zero-order conversion to time.
pub fn zero_order_time(
  initial : Double,
  rate_constant : Double,
  conversion : Double,
) -> Double {
  initial.max(0.0) * clamp_conversion(conversion) / rate_constant.max(1.0e-12)
}

///|
/// Invert a first-order conversion to time.
pub fn first_order_time(rate_constant : Double, conversion : Double) -> Double {
  conversion_time_first_order(rate_constant, conversion)
}

///|
/// Invert a second-order conversion to time.
pub fn second_order_time(
  initial : Double,
  rate_constant : Double,
  conversion : Double,
) -> Double {
  let c0 = initial.max(1.0e-12)
  clamp_conversion(conversion) /
  (rate_constant.max(1.0e-12) * c0 * (1.0 - clamp_conversion(conversion)))
}

///|
/// Integrated first-order exposure.
pub fn first_order_exposure(rate_constant : Double, time : Double) -> Double {
  rate_constant.max(0.0) * time.max(0.0)
}

///|
/// Integrated second-order exposure.
pub fn second_order_exposure(
  rate_constant : Double,
  concentration : Double,
  time : Double,
) -> Double {
  rate_constant.max(0.0) * concentration.max(0.0) * time.max(0.0)
}

///|
/// Consecutive first-order intermediate concentration.
pub fn series_intermediate(
  initial : Double,
  first_rate : Double,
  second_rate : Double,
  time : Double,
) -> Double {
  let a = first_rate.max(0.0)
  let b = second_rate.max(0.0)
  let t = time.max(0.0)
  if (a - b).abs() <= 1.0e-12 {
    initial.max(0.0) * a * t * @math.exp(-a * t)
  } else {
    initial.max(0.0) * a / (b - a) * (@math.exp(-a * t) - @math.exp(-b * t))
  }
}

///|
/// Consecutive first-order product concentration.
pub fn series_product(
  initial : Double,
  first_rate : Double,
  second_rate : Double,
  time : Double,
) -> Double {
  let a = first_order_concentration(initial, first_rate, time)
  let b = series_intermediate(initial, first_rate, second_rate, time)
  (initial.max(0.0) - a - b).max(0.0)
}

///|
/// Parallel product formation rate.
pub fn parallel_product_rate(
  concentration : Double,
  rate_constant : Double,
  order : KineticOrder,
) -> Double {
  let c = concentration.max(0.0)
  match order {
    Zero => rate_constant.max(0.0)
    First => rate_constant.max(0.0) * c
    Second => rate_constant.max(0.0) * c * c
  }
}

///|
/// Product split between two parallel pathways.
pub fn parallel_split(
  concentration : Double,
  first_rate : Double,
  second_rate : Double,
  first_order : KineticOrder,
  second_order : KineticOrder,
) -> (Double, Double) {
  (
    parallel_product_rate(concentration, first_rate, first_order),
    parallel_product_rate(concentration, second_rate, second_order),
  )
}

///|
/// Selectivity of a parallel pair.
pub fn parallel_selectivity(
  first_rate : Double,
  second_rate : Double,
) -> Double {
  selectivity_from_rates(first_rate, second_rate)
}

///|
/// Temperature-corrected rate for a declared reaction.
pub fn corrected_rate(
  reaction : Reaction,
  concentration : Double,
  temperature : Double,
) -> Double {
  reaction.rate(concentration, temperature)
}

///|
/// Rate ratio between two temperatures.
pub fn rate_temperature_ratio(
  reaction : Reaction,
  first_temperature : Double,
  second_temperature : Double,
) -> Double {
  reaction.rate_constant(second_temperature) /
  reaction.rate_constant(first_temperature).max(1.0e-12)
}

///|
/// Conversion from an integrated rate exposure for a selected order.
pub fn conversion_from_exposure(
  exposure : Double,
  order : KineticOrder,
  concentration : Double,
) -> Double {
  let e = exposure.max(0.0)
  match order {
    Zero => clamp_conversion(e / concentration.max(1.0e-12))
    First => clamp_conversion(1.0 - @math.exp(-e))
    Second => clamp_conversion(e / (1.0 + e))
  }
}

///|
/// Generate a concentration trajectory for an order.
pub fn concentration_trajectory(
  initial : Double,
  rate_constant : Double,
  order : KineticOrder,
  duration : Double,
  points : Int,
) -> Array[Double] {
  let values : Array[Double] = []
  let grid = linspace(0.0, duration.max(0.0), points)
  for time in grid {
    let value = match order {
      Zero => zero_order_concentration(initial, rate_constant, time)
      First => first_order_concentration(initial, rate_constant, time)
      Second => second_order_concentration(initial, rate_constant, time)
    }
    values.push(value)
  }
  values
}

///|
/// Estimate a rate constant from two first-order measurements.
pub fn fit_first_order_rate(
  initial : Double,
  final_value : Double,
  time : Double,
) -> Double {
  if initial <= 0.0 || final_value <= 0.0 {
    0.0
  } else {
    natural_log(initial / final_value) / time.max(1.0e-12)
  }
}

///|
/// Estimate a second-order rate constant from two measurements.
pub fn fit_second_order_rate(
  initial : Double,
  final_value : Double,
  time : Double,
) -> Double {
  if initial <= 0.0 || final_value <= 0.0 {
    0.0
  } else {
    (1.0 / final_value - 1.0 / initial) / time.max(1.0e-12)
  }
}

///|
/// Rate-law residual for a measured point.
pub fn rate_residual(
  reaction : Reaction,
  concentration : Double,
  temperature : Double,
  measured : Double,
) -> Double {
  reaction.rate(concentration, temperature) - measured
}

///|
/// Relative rate-law error.
pub fn relative_rate_error(
  reaction : Reaction,
  concentration : Double,
  temperature : Double,
  measured : Double,
) -> Double {
  rate_residual(reaction, concentration, temperature, measured).abs() /
  measured.abs().max(1.0e-12)
}

///|
/// Estimate reaction order from two rate measurements at constant temperature.
pub fn estimate_order(
  first_concentration : Double,
  second_concentration : Double,
  first_rate : Double,
  second_rate : Double,
) -> Double {
  if first_concentration <= 0.0 ||
    second_concentration <= 0.0 ||
    first_rate <= 0.0 ||
    second_rate <= 0.0 {
    0.0
  } else {
    natural_log(second_rate / first_rate) /
    natural_log(second_concentration / first_concentration)
  }
}

///|
/// Estimate a half-life for a first-order rate.
pub fn half_life(rate_constant : Double) -> Double {
  natural_log(2.0) / rate_constant.max(1.0e-12)
}

///|
/// Estimate a half-life for a second-order rate and concentration.
pub fn second_order_half_life(
  rate_constant : Double,
  concentration : Double,
) -> Double {
  1.0 / (rate_constant.max(1.0e-12) * concentration.max(1.0e-12))
}

///|
/// Damkohler number from a residence time.
pub fn damkohler_from_time(
  rate_constant : Double,
  residence : Double,
) -> Double {
  rate_constant.max(0.0) * residence.max(0.0)
}

///|
/// Levenspiel ordinate for a selected order.
pub fn levenspiel_ordinate(
  reaction : Reaction,
  feed : Feed,
  conversion : Double,
) -> Double {
  feed.concentration.max(1.0e-12) /
  reaction
  .rate(concentration_from_conversion(feed, conversion), feed.temperature)
  .max(1.0e-12)
}

///|
/// PFR volume from a tabulated Levenspiel curve.
pub fn pfr_volume_from_curve(
  conversions : ArrayView[Double],
  ordinates : ArrayView[Double],
  flow : Double,
) -> Double {
  flow.max(0.0) * tabulated_trapezoid(conversions, ordinates)
}

///|
/// CSTR volume from an endpoint Levenspiel ordinate.
pub fn cstr_volume_from_endpoint(
  flow : Double,
  target_conversion : Double,
  endpoint_ordinate : Double,
) -> Double {
  flow.max(0.0) *
  clamp_conversion(target_conversion) *
  endpoint_ordinate.max(0.0)
}
