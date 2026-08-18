///|
/// A compact heat-capacity correlation for screening calculations.
pub fn heat_capacity_constant(value : Double) -> Double {
  value.max(1.0e-12)
}

///|
/// Linear temperature heat-capacity correction.
pub fn heat_capacity_linear(
  base : Double,
  slope : Double,
  temperature : Double,
  reference : Double,
) -> Double {
  (base + slope * (temperature - reference)).max(1.0e-12)
}

///|
/// Sensible enthalpy change under a constant heat capacity.
pub fn sensible_enthalpy(
  capacity : Double,
  temperature : Double,
  reference : Double,
) -> Double {
  capacity.max(0.0) * (temperature - reference)
}

///|
/// Sensible enthalpy change under a linear heat-capacity model.
pub fn sensible_enthalpy_linear(
  base : Double,
  slope : Double,
  temperature : Double,
  reference : Double,
) -> Double {
  base * (temperature - reference) +
  slope * ((temperature - reference) * (temperature - reference)) / 2.0
}

///|
/// Convert Celsius to Kelvin with a physical lower bound.
pub fn celsius_to_kelvin(celsius : Double) -> Double {
  (celsius + 273.15).max(1.0)
}

///|
/// Convert Kelvin to Celsius.
pub fn kelvin_to_celsius(kelvin : Double) -> Double {
  kelvin - 273.15
}

///|
/// Convert litres per minute to cubic metres per second.
pub fn liters_per_minute_to_m3_per_second(value : Double) -> Double {
  value.max(0.0) * 1.6666666666666667e-5
}

///|
/// Convert cubic metres per second to litres per minute.
pub fn m3_per_second_to_liters_per_minute(value : Double) -> Double {
  value.max(0.0) * 60000.0
}

///|
/// Convert concentration in mol/L to mol/m3.
pub fn molar_liter_to_molar_meter(value : Double) -> Double {
  value * 1000.0
}

///|
/// Convert concentration in mol/m3 to mol/L.
pub fn molar_meter_to_molar_liter(value : Double) -> Double {
  value / 1000.0
}

///|
/// Compute a heat-capacity flow from flow, density, and specific heat.
pub fn heat_capacity_flow(
  volumetric_flow : Double,
  density : Double,
  specific_heat : Double,
) -> Double {
  volumetric_flow.max(0.0) * density.max(0.0) * specific_heat.max(0.0)
}

///|
/// Estimate an adiabatic temperature rise from heat release.
pub fn adiabatic_rise(
  heat_release : Double,
  heat_capacity_flow : Double,
) -> Double {
  heat_release / heat_capacity_flow.max(1.0e-12)
}

///|
/// Estimate the outlet temperature of a mixed feed and recycle stream.
pub fn mixed_temperature(
  first_flow : Double,
  first_temperature : Double,
  second_flow : Double,
  second_temperature : Double,
) -> Double {
  let total = first_flow.max(0.0) + second_flow.max(0.0)
  if total <= 1.0e-12 {
    0.0
  } else {
    (
      first_flow.max(0.0) * first_temperature +
      second_flow.max(0.0) * second_temperature
    ) /
    total
  }
}

///|
/// Dimensionless Damkohler number for a feed and reaction.
pub fn damkohler_number(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
) -> Double {
  reaction.rate_constant(feed.temperature).max(0.0) *
  volume.max(0.0) /
  feed.volumetric_flow.max(1.0e-12)
}

///|
/// Dimensionless heat-release number for a reaction and feed.
pub fn heat_release_number(reaction : Reaction, feed : Feed) -> Double {
  (-reaction.reaction_enthalpy).max(0.0) *
  feed.concentration.max(0.0) *
  feed.volumetric_flow.max(0.0) /
  feed.heat_capacity_flow.max(1.0e-12)
}

///|
/// Dimensionless jacket strength.
pub fn jacket_number(exchange : HeatExchange, feed : Feed) -> Double {
  exchange.ua.max(0.0) / feed.heat_capacity_flow.max(1.0e-12)
}

///|
/// Peclet-like screening ratio between axial residence and mixing time.
pub fn mixing_ratio(residence : Double, mixing_time : Double) -> Double {
  residence.max(0.0) / mixing_time.max(1.0e-12)
}

///|
/// First-order equilibrium conversion from forward and reverse rates.
pub fn equilibrium_conversion(forward : Double, reverse : Double) -> Double {
  let total = forward.max(0.0) + reverse.max(0.0)
  if total <= 1.0e-12 {
    0.0
  } else {
    forward.max(0.0) / total
  }
}

///|
/// Approach to equilibrium for a reversible first-order reaction.
pub fn reversible_conversion(
  forward : Double,
  reverse : Double,
  time : Double,
) -> Double {
  let total = forward.max(0.0) + reverse.max(0.0)
  if total <= 1.0e-12 {
    0.0
  } else {
    let equilibrium = equilibrium_conversion(forward, reverse)
    equilibrium * (1.0 - @math.exp(-total * time.max(0.0)))
  }
}

///|
/// Log-mean temperature difference for a counter-current exchanger.
pub fn log_mean_temperature_difference(
  delta_hot : Double,
  delta_cold : Double,
) -> Double {
  let a = delta_hot.abs().max(1.0e-12)
  let b = delta_cold.abs().max(1.0e-12)
  if (a - b).abs() <= 1.0e-12 {
    a
  } else {
    (a - b) / natural_log(a / b)
  }
}

///|
/// Heat transfer duty from UA and a temperature driving force.
pub fn exchanger_duty(
  ua : Double,
  delta_hot : Double,
  delta_cold : Double,
) -> Double {
  ua.max(0.0) * log_mean_temperature_difference(delta_hot, delta_cold)
}

///|
/// Estimate a required UA from a duty and terminal temperature differences.
pub fn required_ua(
  duty : Double,
  delta_hot : Double,
  delta_cold : Double,
) -> Double {
  duty.abs() /
  log_mean_temperature_difference(delta_hot, delta_cold).max(1.0e-12)
}

///|
/// Clamp an engineering temperature to a declared operating window.
pub fn clamp_temperature(
  temperature : Double,
  minimum : Double,
  maximum : Double,
) -> Double {
  temperature.clamp(min=minimum.min(maximum), max=maximum.max(minimum))
}

///|
/// Clamp a rate constant to a safe non-negative interval.
pub fn clamp_rate_constant(
  value : Double,
  minimum : Double,
  maximum : Double,
) -> Double {
  value.clamp(
    min=minimum.min(maximum).max(0.0),
    max=maximum.max(minimum).max(0.0),
  )
}

///|
/// Compute a normalized Arrhenius temperature multiplier.
pub fn arrhenius_multiplier(
  activation_energy : Double,
  temperature : Double,
  reference : Double,
) -> Double {
  if activation_energy == 0.0 {
    1.0
  } else {
    @math.exp(
      -activation_energy /
      8.31446261815324 *
      (1.0 / temperature.max(1.0) - 1.0 / reference.max(1.0)),
    )
  }
}

///|
/// Estimate the temperature at which a rate reaches a target multiplier.
pub fn temperature_for_multiplier(
  activation_energy : Double,
  multiplier : Double,
  reference : Double,
) -> Double {
  if activation_energy.abs() <= 1.0e-12 || multiplier <= 0.0 {
    reference
  } else {
    let denominator = 1.0 / reference.max(1.0) -
      8.31446261815324 * natural_log(multiplier) / activation_energy
    if denominator <= 1.0e-12 {
      reference
    } else {
      1.0 / denominator
    }
  }
}

///|
/// Heat released per unit feed volume.
pub fn volumetric_heat_release(
  reaction : Reaction,
  feed : Feed,
  conversion : Double,
) -> Double {
  (-reaction.reaction_enthalpy).max(0.0) *
  feed.concentration.max(0.0) *
  clamp_conversion(conversion)
}

///|
/// Heat removal per unit volume from a lumped jacket.
pub fn volumetric_heat_removal(
  exchange : HeatExchange,
  temperature : Double,
  coolant : Double,
) -> Double {
  exchange.ua.max(0.0) * (temperature - coolant).max(0.0)
}

///|
/// Thermal feasibility margin relative to a maximum temperature.
pub fn thermal_margin(temperature : Double, maximum : Double) -> Double {
  maximum - temperature
}

///|
/// True when all thermal values are finite in an engineering range.
pub fn thermal_window_ok(
  temperature : Double,
  minimum : Double,
  maximum : Double,
) -> Bool {
  temperature >= minimum.min(maximum) && temperature <= maximum.max(minimum)
}
