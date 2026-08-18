///|
test "unit conversion round trips preserve values" {
  assert_true(
    (kelvin_to_celsius(celsius_to_kelvin(25.0)) - 25.0).abs() < 1.0e-9,
  )
  assert_true(
    (m3_per_second_to_liters_per_minute(
      liters_per_minute_to_m3_per_second(12.0),
    ) -
    12.0).abs() <
    1.0e-9,
  )
  assert_true(
    (molar_meter_to_molar_liter(molar_liter_to_molar_meter(0.4)) - 0.4).abs() <
    1.0e-9,
  )
}

///|
test "thermal and dimensionless helpers are bounded" {
  let reaction = Reaction::new(
    name="thermal",
    order=First,
    k_ref=0.3,
    reaction_enthalpy=-10000.0,
  )
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
    heat_capacity_flow=5000.0,
  )
  let hx = HeatExchange::new(ua=1000.0, coolant_temperature=290.0)
  assert_true(damkohler_number(reaction, feed, 2.0) > 0.0)
  assert_true(heat_release_number(reaction, feed) > 0.0)
  assert_true(jacket_number(hx, feed) > 0.0)
  assert_true(equilibrium_conversion(1.0, 0.0) == 1.0)
  assert_true(reversible_conversion(1.0, 1.0, 0.0) == 0.0)
  assert_true(log_mean_temperature_difference(10.0, 10.0) == 10.0)
}

///|
test "design metrics identify analytical first-order behavior" {
  let reaction = Reaction::new(name="metrics", order=First, k_ref=0.5)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 2.0)
  let da = damkohler_number(reaction, feed, 2.0)
  assert_true(first_order_pfr_error(point, da) < 1.0e-8)
  assert_true(pfr_advantage_over_cstr(da) > 0.0)
  assert_true(design_point_is_physical(point, feed))
  assert_true(volumetric_productivity(feed, point) > 0.0)
}

///|
test "validation reports expose invalid inputs" {
  assert_true(validate_volume_grid(-1.0, 2.0, 0).has_errors())
  assert_true(validate_temperature_interval(400.0, 300.0).has_errors())
  assert_true(validate_tolerance(0.0, 0).has_errors())
  assert_true(
    validate_controller_settings(
      ControllerConfig::new(
        proportional=1.0,
        integral=0.0,
        derivative=0.0,
        minimum=0.0,
        maximum=1.0,
      ),
      0.0,
      0,
    ).has_errors(),
  )
}

///|
test "profiles and reports preserve empty boundaries" {
  let reaction = Reaction::new(name="empty", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let profile = pfr_profile(reaction, feed, 0.0, points=1)
  assert_eq(profile.length(), 1)
  assert_true(profile[0].conversion == 0.0)
  assert_true(profile_is_monotone(profile))
  assert_true(profile_rate_exposure([]) == 0.0)
  assert_true(profile_to_csv([]).contains("position"))
}

///|
test "uncertainty and benchmark validation are reproducible" {
  let reaction = Reaction::new(name="uncertainty", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let summary = uncertainty_summary(reaction, feed, 2.0, 25)
  assert_true(uncertainty_summary_is_ordered(summary))
  assert_true(summary.samples == 25)
  let cases = benchmark_cases()
  assert_true(benchmark_tolerances_valid(cases))
  assert_eq(first_invalid_benchmark(cases), None)
  assert_eq(complete_benchmark_count(cases), cases.length())
}

///|
test "train validation and cost ranking are stable" {
  let reaction = Reaction::new(name="train", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let stages = [ReactorStage::cstr(volume=1.0), ReactorStage::pfr(volume=1.0)]
  let result = analyze_train(reaction, feed, stages)
  assert_true(validate_train(result).has_errors() == false)
  assert_true(train_mass_balance_residual(feed, result) < 1.0e-8)
  let scores = objective_surface(
    reaction,
    feed,
    [0.0, 1.0, 2.0],
    1.0,
    0.01,
    400.0,
  )
  assert_eq(scores.length(), 3)
  assert_true(best_objective(scores) is Some(_))
}
