///|
let gas_constant : Double = 8.31446261815324

///|
pub fn clamp_conversion(x : Double) -> Double {
  x.clamp(min=0.0, max=0.999999)
}

///|
pub fn Reaction::rate_constant(self : Reaction, temperature : Double) -> Double {
  if self.activation_energy == 0.0 {
    self.k_ref
  } else {
    let inv_t = 1.0 / temperature
    let inv_ref = 1.0 / self.reference_temperature
    self.k_ref *
    @math.exp(-self.activation_energy / gas_constant * (inv_t - inv_ref))
  }
}

///|
pub fn Reaction::rate(
  self : Reaction,
  concentration : Double,
  temperature : Double,
) -> Double {
  let c = concentration.max(0.0)
  let k = self.rate_constant(temperature)
  match self.order {
    Zero => k
    First => k * c
    Second => k * c * c
  }
}

///|
pub fn concentration_from_conversion(
  feed : Feed,
  conversion : Double,
) -> Double {
  feed.concentration * (1.0 - clamp_conversion(conversion))
}

///|
pub fn adiabatic_temperature(
  feed : Feed,
  reaction : Reaction,
  conversion : Double,
) -> Double {
  let heat_release = -reaction.reaction_enthalpy *
    feed.concentration *
    clamp_conversion(conversion) *
    feed.volumetric_flow
  feed.temperature + heat_release / feed.heat_capacity_flow.max(1.0e-12)
}

///|
pub fn heat_removed_by_jacket(
  exchange : HeatExchange,
  reactor_temperature : Double,
) -> Double {
  exchange.ua * (reactor_temperature - exchange.coolant_temperature)
}

///|
pub fn temperature_for_mode(
  mode : ThermalMode,
  feed : Feed,
  reaction : Reaction,
  conversion : Double,
  exchange : HeatExchange?,
) -> Double {
  match mode {
    Isothermal => feed.temperature
    Adiabatic => adiabatic_temperature(feed, reaction, conversion)
    NonIsothermal =>
      match exchange {
        None => adiabatic_temperature(feed, reaction, conversion)
        Some(hx) => {
          let ad = adiabatic_temperature(feed, reaction, conversion)
          let weight = hx.ua / (hx.ua + feed.heat_capacity_flow.max(1.0e-12))
          ad * (1.0 - weight) + hx.coolant_temperature * weight
        }
      }
  }
}

///|
pub fn conversion_time_first_order(k : Double, conversion : Double) -> Double {
  -natural_log(1.0 - clamp_conversion(conversion)) / k.max(1.0e-12)
}

///|
pub fn natural_log(x : Double) -> Double {
  if x <= 0.0 {
    0.0 / 0.0
  } else {
    bisect(-80.0, 80.0, fn(y) { @math.exp(y) - x }).root
  }
}
