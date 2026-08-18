///|
test "regression zero volume" {
  let reaction = Reaction::new(name="r0", order=First, k_ref=1.0)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  assert_true(design_cstr(reaction, feed, 0.0).conversion == 0.0)
  assert_true(design_pfr(reaction, feed, 0.0).conversion == 0.0)
  assert_true(design_batch(reaction, feed, 0.0).conversion == 0.0)
}

///|
test "regression residence time" {
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  assert_true(residence_time(feed, 4.0) == 2.0)
  assert_true(space_time(feed, 4.0) == 2.0)
  assert_true(space_velocity(feed, 4.0) == 0.5)
}

///|
test "regression selectivity" {
  assert_true(parallel_selectivity(2.0, 1.0) > 0.66)
  assert_true(parallel_selectivity(2.0, 1.0) < 0.67)
  assert_true(yield_from_metrics(0.5, 0.8, 1.0) == 0.4)
}

///|
test "regression exponential" {
  let value = first_order_concentration(1.0, 0.3, 2.0)
  assert_true(value > 0.54 && value < 0.55)
  assert_true(first_order_exposure(0.3, 2.0) == 0.6)
}

///|
test "regression adaptive integral" {
  let result = integrate_adaptive(0.0, 2.0, fn(x : Double) { x })
  assert_true((result.value - 2.0).abs() < 1.0e-8)
  assert_true(result.evaluations > 0)
}

///|
test "regression profile exposure" {
  let reaction = Reaction::new(name="profile", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let profile = pfr_profile(reaction, feed, 2.0, points=5)
  assert_true(profile_rate_exposure(profile) >= 0.0)
  assert_true(profile_interpolate(profile, 0.5).position == 0.5)
}

///|
test "regression cost" {
  let reaction = Reaction::new(name="cost", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let cost = estimate_annual_cost(
    design_pfr(reaction, feed, 1.0),
    CostAssumptions::default(),
  )
  assert_true(cost.capital > 0.0)
  assert_true(cost.utilities >= 0.0)
  assert_true(cost.maintenance >= 0.0)
}

///|
test "regression safety" {
  let points : Array[ReactorSweepPoint] = [
    { volume: 0.0, conversion: 0.0, outlet_temperature: 300.0 },
    { volume: 1.0, conversion: 0.2, outlet_temperature: 320.0 },
  ]
  assert_true(last_safe_sweep_point(points, 310.0) is Some(_))
  assert_true(first_unsafe_sweep_point(points, 310.0) is Some(_))
}

///|
test "regression uncertainty" {
  let reaction = Reaction::new(name="uncertainty", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let values = uncertainty_samples(reaction, feed, 1.0, 10)
  assert_eq(values.length(), 10)
  assert_true(values[0] >= 0.0 && values[0] < 1.0)
}

///|
test "regression scenario" {
  let scenario = OperatingScenario::isothermal(
    name="scenario",
    reaction=Reaction::new(name="r", order=First, k_ref=0.1),
    feed=Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
    volume=1.0,
  )
  assert_true(scenario_safety(scenario, 400.0))
  assert_true(scenario_meets_conversion(scenario, 0.0))
  assert_true(scenario_score(scenario, 0.1, 400.0) >= 0.0)
}

///|
test "regression report labels" {
  assert_true(
    cost_to_markdown({
      capital: 1.0,
      utilities: 2.0,
      maintenance: 3.0,
      total: 6.0,
    }).contains("total"),
  )
  assert_true(
    sensitivity_to_markdown({
      conversion_wrt_volume: 0.0,
      conversion_wrt_rate_constant: 0.0,
      conversion_wrt_temperature: 0.0,
      temperature_wrt_volume: 0.0,
      volume_wrt_target_conversion: 0.0,
    }).contains("derivative"),
  )
}
