///|
/// Space velocity in inverse time.
pub fn space_velocity(feed : Feed, volume : Double) -> Double {
  feed.volumetric_flow.max(0.0) / volume.max(1.0e-12)
}

///|
/// Volumetric productivity for a design point.
pub fn volumetric_productivity(feed : Feed, point : DesignPoint) -> Double {
  feed.concentration.max(0.0) *
  point.conversion *
  feed.volumetric_flow.max(0.0) /
  point.volume.max(1.0e-12)
}

///|
/// Molar production rate of the desired product.
pub fn product_molar_flow(
  feed : Feed,
  point : DesignPoint,
  stoichiometric_yield : Double,
) -> Double {
  feed.concentration.max(0.0) *
  feed.volumetric_flow.max(0.0) *
  point.conversion *
  stoichiometric_yield.clamp(min=0.0, max=1.0)
}

///|
/// Conversion inferred from an inlet and outlet mass flow.
pub fn conversion_from_flows(inlet : Double, outlet : Double) -> Double {
  if inlet <= 1.0e-12 {
    0.0
  } else {
    clamp_conversion(1.0 - outlet / inlet)
  }
}

///|
/// Outlet flow under constant-density assumptions.
pub fn outlet_flow(feed : Feed, point : DesignPoint) -> Double {
  feed.volumetric_flow.max(0.0) * (1.0 - point.conversion)
}

///|
/// Residence-time ratio between two designs.
pub fn residence_time_ratio(
  first : DesignPoint,
  second : DesignPoint,
) -> Double {
  first.residence_time / second.residence_time.max(1.0e-12)
}

///|
/// Conversion improvement per added reactor volume.
pub fn incremental_conversion_rate(
  previous : DesignPoint,
  next : DesignPoint,
) -> Double {
  (next.conversion - previous.conversion) /
  (next.volume - previous.volume).abs().max(1.0e-12)
}

///|
/// Selectivity from desired and undesired product rates.
pub fn selectivity_from_rates(desired : Double, undesired : Double) -> Double {
  let total = desired.max(0.0) + undesired.max(0.0)
  if total <= 1.0e-12 {
    0.0
  } else {
    desired.max(0.0) / total
  }
}

///|
/// Yield from conversion and selectivity.
pub fn yield_from_metrics(
  conversion : Double,
  selectivity : Double,
  stoichiometric_factor : Double,
) -> Double {
  clamp_conversion(conversion) *
  selectivity.clamp(min=0.0, max=1.0) *
  stoichiometric_factor.max(0.0)
}

///|
/// Carbon or atom balance closure from measured flows.
pub fn balance_closure(
  inlet : Double,
  outlet : Double,
  side_products : Double,
) -> Double {
  if inlet.abs() <= 1.0e-12 {
    0.0
  } else {
    1.0 - (outlet + side_products - inlet).abs() / inlet.abs()
  }
}

///|
/// A dimensionless conversion residual.
pub fn conversion_residual(expected : Double, actual : Double) -> Double {
  (actual - expected).abs() / expected.abs().max(1.0e-12)
}

///|
/// A dimensionless temperature residual.
pub fn temperature_residual(expected : Double, actual : Double) -> Double {
  (actual - expected).abs() / expected.abs().max(1.0)
}

///|
/// Weighted quality score for a design calculation.
pub fn design_quality_score(
  conversion_error : Double,
  temperature_error : Double,
  mass_balance_error : Double,
  conversion_weight : Double,
  temperature_weight : Double,
  balance_weight : Double,
) -> Double {
  1.0 -
  (
    conversion_weight.max(0.0) * conversion_error.abs() +
    temperature_weight.max(0.0) * temperature_error.abs() +
    balance_weight.max(0.0) * mass_balance_error.abs()
  )
}

///|
/// Calculate the CSTR/PFR conversion advantage at equal Damkohler number.
pub fn pfr_advantage_over_cstr(damkohler : Double) -> Double {
  let da = damkohler.max(0.0)
  1.0 - @math.exp(-da) - da / (1.0 + da)
}

///|
/// Compare a design point with an analytical first-order PFR oracle.
pub fn first_order_pfr_error(point : DesignPoint, damkohler : Double) -> Double {
  (point.conversion - (1.0 - @math.exp(-damkohler.max(0.0)))).abs()
}

///|
/// Compare a design point with an analytical first-order CSTR oracle.
pub fn first_order_cstr_error(
  point : DesignPoint,
  damkohler : Double,
) -> Double {
  (point.conversion - damkohler.max(0.0) / (1.0 + damkohler.max(0.0))).abs()
}

///|
/// Mean conversion of a sweep.
pub fn mean_sweep_conversion(points : ArrayView[ReactorSweepPoint]) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    points.fold(init=0.0, fn(acc, point) { acc + point.conversion }) /
    Double::from_int(points.length())
  }
}

///|
/// Maximum conversion of a sweep.
pub fn maximum_sweep_conversion(
  points : ArrayView[ReactorSweepPoint],
) -> Double {
  points.fold(init=0.0, fn(acc, point) { acc.max(point.conversion) })
}

///|
/// Minimum conversion of a sweep.
pub fn minimum_sweep_conversion(
  points : ArrayView[ReactorSweepPoint],
) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    points.fold(init=1.0, fn(acc, point) { acc.min(point.conversion) })
  }
}

///|
/// Temperature range of a sweep.
pub fn sweep_temperature_range(
  points : ArrayView[ReactorSweepPoint],
) -> (Double, Double) {
  if points.length() == 0 {
    (0.0, 0.0)
  } else {
    let minimum = points.fold(init=1.0e30, fn(acc, point) {
      acc.min(point.outlet_temperature)
    })
    let maximum = points.fold(init=-1.0e30, fn(acc, point) {
      acc.max(point.outlet_temperature)
    })
    (minimum, maximum)
  }
}

///|
/// Check whether a sweep is sorted by volume.
pub fn sweep_is_sorted(points : ArrayView[ReactorSweepPoint]) -> Bool {
  if points.length() < 2 {
    true
  } else {
    for i = 1; i < points.length(); i = i + 1 {
      if points[i].volume < points[i - 1].volume {
        return false
      }
    }
    true
  }
}

///|
/// Return the first sweep point meeting a conversion target.
pub fn first_sweep_target(
  points : ArrayView[ReactorSweepPoint],
  target : Double,
) -> ReactorSweepPoint? {
  for point in points {
    if point.conversion >= clamp_conversion(target) {
      return Some(point)
    }
  }
  None
}

///|
/// Estimate a conversion target from a desired production rate.
pub fn target_conversion_for_production(
  feed : Feed,
  production : Double,
  product_yield : Double,
) -> Double {
  let capacity = feed.concentration.max(0.0) *
    feed.volumetric_flow.max(0.0) *
    product_yield.max(1.0e-12)
  clamp_conversion(production.max(0.0) / capacity.max(1.0e-12))
}

///|
/// Estimate volume required for a production target with a PFR point.
pub fn volume_for_production(
  reaction : Reaction,
  feed : Feed,
  production : Double,
  product_yield : Double,
) -> Double {
  required_pfr_volume(
    reaction,
    feed,
    target_conversion_for_production(feed, production, product_yield),
  )
}

///|
/// Check common physical invariants of a design point.
pub fn design_point_is_physical(point : DesignPoint, feed : Feed) -> Bool {
  point.volume >= 0.0 &&
  point.conversion >= 0.0 &&
  point.conversion < 1.0 &&
  point.outlet_concentration >= -1.0e-9 &&
  point.outlet_concentration <= feed.concentration + 1.0e-9
}
