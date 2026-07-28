///|
fn assert_close(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Unit raise {
  assert_true((actual - expected).abs() <= tolerance)
}

///|
test "first order CSTR and PFR match textbook equations" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.5)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  let cstr = design_cstr(reaction, feed, 4.0)
  let pfr = design_pfr(reaction, feed, 4.0)
  assert_close(cstr.conversion, 0.5, 1.0e-8)
  assert_close(pfr.conversion, 0.6321205588, 1.0e-7)
  assert_true(pfr.conversion > cstr.conversion)
}

///|
test "second order CSTR root stays inside physical conversion range" {
  let reaction = Reaction::new(name="A + B -> C", order=Second, k_ref=0.25)
  let feed = Feed::new(
    concentration=2.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_cstr(reaction, feed, 3.0)
  assert_true(point.conversion > 0.0)
  assert_true(point.conversion < 1.0)
  assert_true(point.outlet_concentration >= 0.0)
}

///|
test "batch reactor reaches same first-order conversion at equal time as PFR" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=310.0,
  )
  let batch = design_batch(reaction, feed, 5.0)
  let pfr = design_pfr(reaction, feed, 5.0)
  assert_close(batch.conversion, pfr.conversion, 1.0e-8)
}

///|
test "Arrhenius rate increases with temperature for positive activation energy" {
  let reaction = Reaction::new(
    name="temperature sensitive",
    order=First,
    k_ref=0.1,
    activation_energy=50000.0,
    reference_temperature=300.0,
  )
  assert_true(reaction.rate_constant(340.0) > reaction.rate_constant(300.0))
}

///|
test "bisection finds a simple root" {
  let root = bisect(0.0, 2.0, fn(x) { x * x - 2.0 })
  assert_true(root.converged)
  assert_close(root.root, 1.41421356, 1.0e-6)
}

///|
test "trapezoid integration is adequate for smooth design curves" {
  let area = integrate_trapezoid(0.0, 1.0, 200, fn(x) { x * x })
  assert_close(area, 0.333333, 1.0e-4)
}

///|
test "adiabatic exothermic CSTR raises outlet temperature" {
  let reaction = Reaction::new(
    name="exothermic",
    order=First,
    k_ref=0.03,
    reaction_enthalpy=-50000.0,
  )
  let feed = Feed::new(
    concentration=0.8,
    volumetric_flow=1.0,
    temperature=315.0,
    heat_capacity_flow=5000.0,
  )
  let point = design_cstr(reaction, feed, 20.0, thermal_mode=Adiabatic)
  assert_true(point.outlet_temperature > feed.temperature)
}

///|
test "jacketed non-isothermal mode pulls temperature toward coolant" {
  let reaction = Reaction::new(
    name="cooled reaction",
    order=First,
    k_ref=0.05,
    reaction_enthalpy=-80000.0,
  )
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=330.0,
    heat_capacity_flow=6000.0,
  )
  let hx = HeatExchange::new(ua=3000.0, coolant_temperature=300.0)
  let ad = design_cstr(reaction, feed, 15.0, thermal_mode=Adiabatic)
  let cooled = design_cstr(
    reaction,
    feed,
    15.0,
    thermal_mode=NonIsothermal,
    exchange=hx,
  )
  assert_true(cooled.outlet_temperature < ad.outlet_temperature)
}

///|
test "volume solvers hit requested conversion" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let vc = required_cstr_volume(reaction, feed, 0.6)
  let vp = required_pfr_volume(reaction, feed, 0.6)
  assert_close(design_cstr(reaction, feed, vc).conversion, 0.6, 1.0e-5)
  assert_close(design_pfr(reaction, feed, vp).conversion, 0.6, 1.0e-5)
}

///|
test "sweep keeps endpoints and monotonic trend" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let points = sweep_pfr(reaction, feed, 10.0, 6)
  assert_eq(points.length(), 6)
  assert_close(points[0].volume, 0.0, 1.0e-12)
  assert_close(points[5].volume, 10.0, 1.0e-12)
  assert_true(points[5].conversion > points[1].conversion)
}

///|
test "included example cases produce usable positive values" {
  let cstr = ethyl_acetate_saponification()
  let series = first_order_series_example()
  let boundary = exothermic_cstr_boundary()
  assert_true(cstr.conversion > 0.0)
  assert_true(series > 0.0)
  assert_true(boundary.max_safe_volume > 0.0)
}
