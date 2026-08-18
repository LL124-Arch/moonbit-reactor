///|
test "batch curves are monotone and target-searchable" {
  let reaction = Reaction::new(name="batch curve", order=First, k_ref=0.4)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let times = linspace(0.0, 5.0, 21)
  let conversions = batch_conversion_curve(reaction, feed, times)
  let concentrations = batch_concentration_curve(reaction, feed, times)
  let rates = batch_rate_curve(reaction, feed, times)
  assert_eq(conversions.length(), 21)
  assert_eq(concentrations.length(), 21)
  assert_eq(rates.length(), 21)
  assert_true(batch_curve_is_monotone(conversions))
  assert_true(conversions[20] > conversions[0])
  assert_true(batch_time_for_target(reaction, feed, 0.5, 5.0, 21) is Some(_))
  assert_true(batch_time_for_target(reaction, feed, 0.99, 0.0, 1) is None)
}

///|
test "batch productivity has a deterministic optimum" {
  let reaction = Reaction::new(name="cycle", order=First, k_ref=0.5)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let result = optimize_batch_cycle(reaction, feed, 10.0, 1.0, 25)
  assert_true(result is Some(_))
  assert_true(batch_productivity(feed, 0.5, 2.0, 1.0) > 0.0)
  assert_true(batch_conversion_gain(reaction, feed, 0.0, 2.0) > 0.0)
  assert_true(average_batch_conversion(reaction, feed, 2.0, 10) > 0.0)
}

///|
test "reactor curve comparison preserves volume samples" {
  let reaction = Reaction::new(name="curve", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let volumes = [0.0, 1.0, 2.0, 3.0]
  let curve = compare_reactor_curves(reaction, feed, volumes)
  assert_eq(curve.length(), volumes.length())
  assert_true(curve[0].1 == 0.0 && curve[0].2 == 0.0)
  assert_true(curve[3].2 > curve[3].1)
  assert_true(average_pfr_advantage(curve) > 0.0)
  assert_true(curve_volume_for_target(curve, 0.2, true) is Some(_))
  assert_true(conversion_volume_area(curve, true) > 0.0)
}

///|
test "batch design windows annotate every sample" {
  let reaction = Reaction::new(name="window", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  let window = batch_design_window(reaction, feed, 0.0, 400.0, 5.0, 10)
  assert_eq(window.length(), 10)
  assert_true(window[0].feasible)
  assert_true(minimum_feasible_volume(window) is Some(_))
  assert_true(envelope_to_markdown(window).contains("feasible"))
}

///|
test "thermal property helpers preserve units and signs" {
  assert_true(heat_capacity_constant(-1.0) > 0.0)
  assert_true(sensible_enthalpy(10.0, 310.0, 300.0) == 100.0)
  assert_true(sensible_enthalpy_linear(10.0, 1.0, 310.0, 300.0) == 150.0)
  assert_true(adiabatic_rise(100.0, 10.0) == 10.0)
  assert_true(mixed_temperature(1.0, 300.0, 1.0, 400.0) == 350.0)
  assert_true(arrhenius_multiplier(0.0, 300.0, 300.0) == 1.0)
  assert_true(temperature_for_multiplier(0.0, 2.0, 300.0) == 300.0)
  assert_true(
    volumetric_heat_release(
      Reaction::new(name="q", order=First, k_ref=1.0, reaction_enthalpy=-10.0),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
      0.5,
    ) ==
    5.0,
  )
}
