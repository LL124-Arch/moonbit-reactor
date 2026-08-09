///|
pub fn reversible_first_order_rate(
  model : ReversibleFirstOrder,
  reactant_concentration : Double,
  product_concentration : Double,
) -> Double {
  let reactant = reactant_concentration.max(0.0)
  let product = product_concentration.max(0.0)
  let raw = model.forward_rate.max(0.0) * reactant -
    model.reverse_rate.max(0.0) * product
  if model.equilibrium_concentration > 0.0 &&
    product >= model.equilibrium_concentration &&
    raw > 0.0 {
    0.0
  } else {
    raw
  }
}

///|
pub fn series_first_order_batch(
  initial_concentration : Double,
  first_rate : Double,
  second_rate : Double,
  time : Double,
) -> SeriesReactionResult {
  let c0 = initial_concentration.max(0.0)
  let k1 = first_rate.max(0.0)
  let k2 = second_rate.max(0.0)
  let t = time.max(0.0)
  let ca = c0 * @math.exp(-k1 * t)
  let cb = if k1 == k2 {
    c0 * k1 * t * @math.exp(-k1 * t)
  } else {
    c0 * k1 / (k2 - k1) * (@math.exp(-k1 * t) - @math.exp(-k2 * t))
  }
  let intermediate = cb.max(0.0)
  let product = (c0 - ca - intermediate).max(0.0)
  let converted = intermediate + product
  {
    intermediate_concentration: intermediate,
    product_concentration: product,
    intermediate_selectivity: if converted <= 0.0 {
      0.0
    } else {
      (intermediate / converted).clamp(min=0.0, max=1.0)
    },
  }
}

///|
pub fn parallel_first_order_rates(
  concentration : Double,
  product_a_rate_constant : Double,
  product_b_rate_constant : Double,
) -> ParallelReactionResult {
  let c = concentration.max(0.0)
  let ka = product_a_rate_constant.max(0.0)
  let kb = product_b_rate_constant.max(0.0)
  let rate_a = ka * c
  let rate_b = kb * c
  let total = rate_a + rate_b
  {
    product_a_rate: rate_a,
    product_b_rate: rate_b,
    product_a_selectivity: if total <= 0.0 {
      0.0
    } else {
      rate_a / total
    },
    product_b_selectivity: if total <= 0.0 {
      0.0
    } else {
      rate_b / total
    },
  }
}
