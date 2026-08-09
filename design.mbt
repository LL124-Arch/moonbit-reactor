///|
pub fn cstr_conversion_isothermal(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
) -> Double {
  let tau = volume / feed.volumetric_flow.max(1.0e-12)
  let k = reaction.rate_constant(feed.temperature)
  match reaction.order {
    Zero => clamp_conversion(k * tau / feed.concentration.max(1.0e-12))
    First => clamp_conversion(k * tau / (1.0 + k * tau))
    Second => {
      let c0 = feed.concentration.max(1.0e-12)
      let root = bisect(0.0, 0.999999, fn(x) {
        x - tau * k * c0 * (1.0 - x) * (1.0 - x)
      })
      clamp_conversion(root.root)
    }
  }
}

///|
pub fn pfr_conversion_isothermal(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
) -> Double {
  let tau = volume / feed.volumetric_flow.max(1.0e-12)
  let k = reaction.rate_constant(feed.temperature)
  match reaction.order {
    Zero => clamp_conversion(k * tau / feed.concentration.max(1.0e-12))
    First => clamp_conversion(1.0 - @math.exp(-k * tau))
    Second => {
      let c0 = feed.concentration.max(1.0e-12)
      clamp_conversion(k * c0 * tau / (1.0 + k * c0 * tau))
    }
  }
}

///|
pub fn batch_conversion_isothermal(
  reaction : Reaction,
  feed : Feed,
  time : Double,
) -> Double {
  let k = reaction.rate_constant(feed.temperature)
  match reaction.order {
    Zero => clamp_conversion(k * time / feed.concentration.max(1.0e-12))
    First => clamp_conversion(1.0 - @math.exp(-k * time))
    Second => {
      let c0 = feed.concentration.max(1.0e-12)
      clamp_conversion(k * c0 * time / (1.0 + k * c0 * time))
    }
  }
}

///|
pub fn design_cstr(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> DesignPoint {
  let x = if thermal_mode == Isothermal {
    cstr_conversion_isothermal(reaction, feed, volume)
  } else {
    solve_nonisothermal_conversion(
      Cstr,
      reaction,
      feed,
      volume,
      thermal_mode,
      exchange,
    )
  }
  make_design_point(Cstr, thermal_mode, reaction, feed, volume, x, exchange)
}

///|
pub fn design_pfr(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> DesignPoint {
  let x = if thermal_mode == Isothermal {
    pfr_conversion_isothermal(reaction, feed, volume)
  } else {
    solve_nonisothermal_conversion(
      Pfr,
      reaction,
      feed,
      volume,
      thermal_mode,
      exchange,
    )
  }
  make_design_point(Pfr, thermal_mode, reaction, feed, volume, x, exchange)
}

///|
pub fn design_batch(
  reaction : Reaction,
  feed : Feed,
  time : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> DesignPoint {
  let x = if thermal_mode == Isothermal {
    batch_conversion_isothermal(reaction, feed, time)
  } else {
    solve_nonisothermal_batch(reaction, feed, time, thermal_mode, exchange)
  }
  let volume = feed.volumetric_flow * time
  make_design_point(Batch, thermal_mode, reaction, feed, volume, x, exchange)
}

///|
fn make_design_point(
  kind : ReactorKind,
  mode : ThermalMode,
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  conversion : Double,
  exchange : HeatExchange?,
) -> DesignPoint {
  let x = clamp_conversion(conversion)
  let cout = concentration_from_conversion(feed, x)
  let tout = temperature_for_mode(mode, feed, reaction, x, exchange)
  let heat = match exchange {
    None => 0.0
    Some(hx) => heat_removed_by_jacket(hx, tout)
  }
  {
    kind,
    thermal_mode: mode,
    volume,
    residence_time: residence_time(feed, volume),
    conversion: x,
    outlet_concentration: cout,
    outlet_temperature: tout,
    heat_removed: heat,
    rate_at_outlet: reaction.rate(cout, tout),
  }
}

///|
fn solve_nonisothermal_conversion(
  kind : ReactorKind,
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  mode : ThermalMode,
  exchange : HeatExchange?,
) -> Double {
  let tau = volume / feed.volumetric_flow.max(1.0e-12)
  let c0 = feed.concentration.max(1.0e-12)
  let root = bisect(0.0, 0.999999, fn(x) {
    let t = temperature_for_mode(mode, feed, reaction, x, exchange)
    let c = c0 * (1.0 - x)
    let r = reaction.rate(c, t).max(1.0e-12)
    match kind {
      Cstr => x - tau * r / c0
      Pfr => {
        let area = integrate_trapezoid(0.0, x, 64, fn(z) {
          let tz = temperature_for_mode(mode, feed, reaction, z, exchange)
          let cz = c0 * (1.0 - z)
          c0 / reaction.rate(cz, tz).max(1.0e-12)
        })
        area - tau
      }
      Batch => x
    }
  })
  clamp_conversion(root.root)
}

///|
fn solve_nonisothermal_batch(
  reaction : Reaction,
  feed : Feed,
  time : Double,
  mode : ThermalMode,
  exchange : HeatExchange?,
) -> Double {
  let steps = 160
  let dt = time / Double::from_int(steps)
  let c0 = feed.concentration.max(1.0e-12)
  euler_integrate(0.0, dt, steps, fn(_, x) {
    let xc = clamp_conversion(x)
    let temp = temperature_for_mode(mode, feed, reaction, xc, exchange)
    reaction.rate(c0 * (1.0 - xc), temp) / c0
  })
}

///|
pub fn required_cstr_volume(
  reaction : Reaction,
  feed : Feed,
  target_conversion : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> Double {
  let target = clamp_conversion(target_conversion)
  let root = bisect(
    0.0,
    1.0e6,
    fn(v) {
      solve_nonisothermal_or_isothermal(
        Cstr,
        reaction,
        feed,
        v,
        thermal_mode,
        exchange,
      ) -
      target
    },
    settings=SolverSettings::loose(),
  )
  root.root
}

///|
pub fn required_pfr_volume(
  reaction : Reaction,
  feed : Feed,
  target_conversion : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> Double {
  let target = clamp_conversion(target_conversion)
  let root = bisect(
    0.0,
    1.0e6,
    fn(v) {
      solve_nonisothermal_or_isothermal(
        Pfr,
        reaction,
        feed,
        v,
        thermal_mode,
        exchange,
      ) -
      target
    },
    settings=SolverSettings::loose(),
  )
  root.root
}

///|
fn solve_nonisothermal_or_isothermal(
  kind : ReactorKind,
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  mode : ThermalMode,
  exchange : HeatExchange?,
) -> Double {
  if mode == Isothermal {
    match kind {
      Cstr => cstr_conversion_isothermal(reaction, feed, volume)
      Pfr => pfr_conversion_isothermal(reaction, feed, volume)
      Batch => batch_conversion_isothermal(reaction, feed, volume)
    }
  } else {
    solve_nonisothermal_conversion(kind, reaction, feed, volume, mode, exchange)
  }
}
