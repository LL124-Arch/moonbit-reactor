///|
pub fn sweep_cstr(
  reaction : Reaction,
  feed : Feed,
  max_volume : Double,
  points : Int,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> Array[ReactorSweepPoint] {
  sweep_reactor(
    fn(v) {
      if exchange is Some(hx) {
        design_cstr(reaction, feed, v, thermal_mode~, exchange=hx)
      } else {
        design_cstr(reaction, feed, v, thermal_mode~)
      }
    },
    max_volume,
    points,
  )
}

///|
pub fn sweep_pfr(
  reaction : Reaction,
  feed : Feed,
  max_volume : Double,
  points : Int,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> Array[ReactorSweepPoint] {
  sweep_reactor(
    fn(v) {
      if exchange is Some(hx) {
        design_pfr(reaction, feed, v, thermal_mode~, exchange=hx)
      } else {
        design_pfr(reaction, feed, v, thermal_mode~)
      }
    },
    max_volume,
    points,
  )
}

///|
fn sweep_reactor(
  design : (Double) -> DesignPoint,
  max_volume : Double,
  points : Int,
) -> Array[ReactorSweepPoint] {
  let n = points.max(2)
  let out : Array[ReactorSweepPoint] = []
  for i in 0..<n {
    let v = max_volume * Double::from_int(i) / Double::from_int(n - 1)
    let p = design(v)
    out.push({
      volume: v,
      conversion: p.conversion,
      outlet_temperature: p.outlet_temperature,
    })
  }
  out
}

///|
pub fn find_temperature_boundary(
  reaction : Reaction,
  feed : Feed,
  max_volume : Double,
  max_temperature : Double,
  thermal_mode? : ThermalMode = Adiabatic,
  exchange? : HeatExchange,
) -> SafetyBoundary {
  let root = bisect(
    0.0,
    max_volume,
    fn(v) {
      let p = if exchange is Some(hx) {
        design_cstr(reaction, feed, v, thermal_mode~, exchange=hx)
      } else {
        design_cstr(reaction, feed, v, thermal_mode~)
      }
      p.outlet_temperature - max_temperature
    },
    settings=SolverSettings::loose(),
  )
  let boundary_volume = if root.converged { root.root } else { max_volume }
  let point = if exchange is Some(hx) {
    design_cstr(reaction, feed, boundary_volume, thermal_mode~, exchange=hx)
  } else {
    design_cstr(reaction, feed, boundary_volume, thermal_mode~)
  }
  {
    max_safe_volume: boundary_volume,
    max_safe_residence_time: point.residence_time,
    hot_spot_temperature: point.outlet_temperature,
    conversion_at_boundary: point.conversion,
    limited_by_temperature: root.converged,
  }
}

///|
pub fn selectivity_series_first_order(
  k1 : Double,
  k2 : Double,
  residence_time : Double,
) -> Double {
  if k1 == k2 {
    let cb = k1 * residence_time * @math.exp(-k1 * residence_time)
    cb.max(0.0)
  } else {
    let cb = k1 /
      (k2 - k1) *
      (@math.exp(-k1 * residence_time) - @math.exp(-k2 * residence_time))
    cb.max(0.0)
  }
}
