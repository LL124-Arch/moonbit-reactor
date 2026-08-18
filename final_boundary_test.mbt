///|
test "empty collection API boundaries" {
  assert_eq(
    pfr_profile(
      Reaction::new(name="empty", order=First, k_ref=0.1),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
      1.0,
      points=0,
    ).length(),
    1,
  )
  assert_eq(
    batch_profile(
      Reaction::new(name="empty", order=First, k_ref=0.1),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
      1.0,
      points=0,
    ).length(),
    1,
  )
  assert_eq(
    simulate_controller(
      ControllerConfig::new(
        proportional=1.0,
        integral=0.0,
        derivative=0.0,
        minimum=0.0,
        maximum=1.0,
      ),
      1.0,
      0.0,
      1.0,
      1.0,
      0.1,
      0,
    ).length(),
    0,
  )
  assert_eq(
    uncertainty_samples(
      Reaction::new(name="empty", order=First, k_ref=0.1),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
      1.0,
      0,
    ).length(),
    0,
  )
}

///|
test "large input guards stay finite" {
  let reaction = Reaction::new(
    name="large",
    order=Second,
    k_ref=1.0e6,
    activation_energy=1.0e5,
  )
  let feed = Feed::new(
    concentration=1.0e6,
    volumetric_flow=1.0e-12,
    temperature=1000.0,
    heat_capacity_flow=1.0e-12,
  )
  let point = design_pfr(reaction, feed, 1.0e6)
  assert_true(point.conversion >= 0.0 && point.conversion < 1.0)
  assert_true(point.outlet_concentration >= 0.0)
  assert_true(validate_design_point(point, feed).has_errors() == false)
}

///|
test "scenario transformation boundaries" {
  let base = OperatingScenario::isothermal(
    name="base",
    reaction=Reaction::new(name="r", order=First, k_ref=0.1),
    feed=Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
    volume=1.0,
  )
  let shifted = shift_scenario_temperature(base, -50.0)
  let scaled = scale_scenario_rate(base, -2.0)
  let flowed = scale_scenario_flow(base, -2.0)
  assert_true(shifted.feed.temperature == 250.0)
  assert_true(scaled.reaction.k_ref == 0.0)
  assert_true(flowed.feed.volumetric_flow == 0.0)
}

///|
test "curve utility boundaries" {
  let empty : Array[(Double, Double, Double)] = []
  assert_true(average_pfr_advantage(empty) == 0.0)
  assert_true(curve_volume_for_target(empty, 0.5, true) is None)
  assert_true(conversion_volume_area(empty, false) == 0.0)
  assert_eq(
    compare_reactor_curves(
      Reaction::new(name="r", order=First, k_ref=0.1),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
      [],
    ).length(),
    0,
  )
}

///|
test "pressure and flow boundaries" {
  assert_true(flow_velocity(0.0, 1.0) == 0.0)
  assert_true(pressure_drop(0.0, 1.0, 1000.0, 1.0, 0.1) == 0.0)
  assert_true(reynolds_number(0.0, 1.0, 1.0, 0.001) == 0.0)
  assert_true(laminar_friction_factor(0.0) == 64.0)
  assert_true(blasius_friction_factor(0.0) > 0.0)
}

///|
test "reporting empty boundaries" {
  assert_true(controller_to_csv([]).contains("index"))
  assert_true(profile_summary([]) == "empty profile")
  assert_true(
    train_to_csv({
      stages: [],
      final_conversion: 0.0,
      total_volume: 0.0,
      total_residence_time: 0.0,
    }).contains("final_conversion"),
  )
  assert_true(objective_surface_to_csv([]).contains("volume"))
  assert_true(benchmark_results_to_markdown([]).contains("status"))
}

///|
test "unit and metric boundaries" {
  assert_true(liters_per_minute_to_m3_per_second(-1.0) == 0.0)
  assert_true(molar_liter_to_molar_meter(0.0) == 0.0)
  assert_true(mixed_temperature(0.0, 300.0, 0.0, 400.0) == 0.0)
  assert_true(selectivity_from_rates(0.0, 0.0) == 0.0)
  assert_true(balance_closure(0.0, 1.0, 1.0) == 0.0)
  assert_true(
    cost_savings(
      { capital: 1.0, utilities: 1.0, maintenance: 1.0, total: 3.0 },
      { capital: 2.0, utilities: 2.0, maintenance: 2.0, total: 6.0 },
    ) ==
    -3.0,
  )
}

///|
test "search grid boundaries" {
  let config = SearchConfig::new(minimum=2.0, maximum=-2.0, steps=0)
  assert_true(
    config.minimum == -2.0 && config.maximum == 2.0 && config.steps == 1,
  )
  assert_eq(uniform_grid(config).length(), 2)
  assert_true(maximum_scalar([]) is None)
  assert_true(minimum_scalar([]) is None)
  assert_true(first_under_volume([], 1.0) is None)
  assert_true(last_over_conversion([], 0.2) is None)
}

///|
test "validation and metadata boundaries" {
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let points : Array[ReactorSweepPoint] = []
  assert_true(validate_sweep(points, feed).has_errors() == false)
  assert_true(validate_feed_window(feed, 290.0, 310.0).has_errors() == false)
  assert_true(
    validate_reaction_temperature(
      Reaction::new(name="r", order=First, k_ref=0.1),
      300.0,
    ).has_errors() ==
    false,
  )
  assert_true(report_row_count("a\nb\n") == 2)
  assert_true(report_contains_all("alpha beta", ["alpha", "beta"]))
}

///|
test "benchmark output is stable across repeated calls" {
  let first = benchmark_report_markdown()
  let second = benchmark_report_markdown()
  assert_true(first == second)
  assert_true(first.length() > 100)
  assert_true(benchmark_report_csv() == benchmark_report_csv())
}
