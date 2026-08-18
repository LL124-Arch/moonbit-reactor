///|
test "engineering API returns finite values across kinetic orders" {
  let orders : Array[KineticOrder] = [Zero, First, Second]
  for order in orders {
    let reaction = Reaction::new(name="order", order~, k_ref=0.1)
    let feed = Feed::new(
      concentration=1.0,
      volumetric_flow=1.0,
      temperature=300.0,
    )
    let cstr = design_cstr(reaction, feed, 1.0)
    let pfr = design_pfr(reaction, feed, 1.0)
    let batch = design_batch(reaction, feed, 1.0)
    assert_true(cstr.conversion >= 0.0 && cstr.conversion < 1.0)
    assert_true(pfr.conversion >= 0.0 && pfr.conversion < 1.0)
    assert_true(batch.conversion >= 0.0 && batch.conversion < 1.0)
    assert_true(design_point_is_physical(cstr, feed))
    assert_true(design_point_is_physical(pfr, feed))
    assert_true(design_point_is_physical(batch, feed))
  }
}

///|
test "negative and zero operating inputs remain guarded" {
  let reaction = Reaction::new(
    name="guard",
    order=First,
    k_ref=-1.0,
    reference_temperature=-1.0,
  )
  let feed = Feed::new(
    concentration=-1.0,
    volumetric_flow=0.0,
    temperature=0.0,
    heat_capacity_flow=0.0,
  )
  let point = design_pfr(reaction, feed, -10.0)
  assert_true(point.conversion >= 0.0 && point.conversion < 1.0)
  assert_true(residence_time(feed, -1.0) <= 0.0)
  assert_true(clamp_conversion(-1.0) == 0.0)
  assert_true(clamp_conversion(2.0) < 1.0)
  assert_true(volume_for_production(reaction, feed, -1.0, 1.0) >= 0.0)
}

///|
test "profiles interpolate at both endpoints" {
  let reaction = Reaction::new(name="interpolate", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let profile = pfr_profile(reaction, feed, 5.0, points=11)
  let first = profile_interpolate(profile, -1.0)
  let last = profile_interpolate(profile, 2.0)
  assert_true(first.position == 0.0)
  assert_true(last.position == 1.0)
  assert_true(first.conversion <= last.conversion)
  assert_true(profile_interpolate([], 0.5).conversion == 0.0)
}

///|
test "controller saturates, releases, and remains bounded" {
  let config = ControllerConfig::new(
    proportional=1.0,
    integral=0.2,
    derivative=0.0,
    minimum=-1.0,
    maximum=1.0,
  )
  let trace = simulate_controller(config, 1.0, 0.0, 1.0, 2.0, 0.1, 30)
  assert_eq(trace.length(), 30)
  assert_true(controller_trace_is_bounded(trace, config))
  assert_true(controller_peak_error(trace, 1.0) >= 0.0)
  assert_true(jacket_duty(300.0, 350.0, 290.0, 1.0) <= 1.0)
  assert_true(
    jacket_heat_removal(
      HeatExchange::new(ua=10.0, coolant_temperature=290.0),
      350.0,
      300.0,
      1.0,
    ) >
    0.0,
  )
}

///|
test "grid and signal operations preserve shape" {
  let grid = linspace(0.0, 10.0, 21)
  let values = grid.map(fn(x) { @math.sin(x) })
  assert_eq(grid.length(), values.length())
  assert_eq(logspace(1.0, 100.0, 5).length(), 5)
  assert_eq(midpoints(grid).length(), 20)
  assert_eq(first_difference(values, 0.5).length(), 20)
  assert_eq(low_pass(values, 0.3).length(), values.length())
  assert_true(sign_change_count(values) > 0)
  assert_true(normalize_to_range(values, 0.0, 1.0)[0] >= 0.0)
}

///|
test "network comparisons report positive totals" {
  let reaction = Reaction::new(name="network", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let stages = equal_volume_cstr_train(4, 8.0)
  let result = run_network(reaction, feed, stages)
  assert_eq(result.stages.length(), 4)
  assert_true(result.total_volume == 8.0)
  assert_true(result.final_conversion > 0.0)
  let analysis = analyze_train(reaction, feed, stages)
  assert_true(analysis.total_residence_time > 0.0)
  assert_true(compare_train_to_single_pfr(reaction, feed, stages).2 <= 1.0)
}

///|
test "cost and objective utilities handle ties" {
  let first : ObjectiveScore = {
    volume: 1.0,
    conversion: 0.5,
    temperature: 300.0,
    score: 2.0,
    feasible: true,
  }
  let second : ObjectiveScore = {
    volume: 2.0,
    conversion: 0.5,
    temperature: 300.0,
    score: 2.0,
    feasible: true,
  }
  assert_true(score_precedes(first, second))
  assert_true(!score_precedes(second, first))
  assert_true(objective_improvement(first, second) == 0.0)
  assert_true(penalty_score(1.0, false, 2.0) < 1.0)
  assert_true(minimum_scalar([first, second]) is Some(_))
}

///|
test "benchmark reports contain every declared case" {
  let cases = benchmark_cases()
  let results = benchmark_results()
  assert_eq(cases.length(), results.length())
  assert_true(benchmark_report_markdown().contains("PASS"))
  assert_true(benchmark_report_csv().contains("absolute_error"))
  assert_true(maximum_benchmark_error(results) >= 0.0)
  assert_true(benchmark_failure_count(results) == 0)
}

///|
test "thermal modes produce deterministic temperatures" {
  let reaction = Reaction::new(
    name="thermal modes",
    order=First,
    k_ref=0.1,
    reaction_enthalpy=-10000.0,
  )
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
    heat_capacity_flow=1000.0,
  )
  let ad = design_pfr(reaction, feed, 2.0, thermal_mode=Adiabatic)
  let jacket = HeatExchange::new(ua=1000.0, coolant_temperature=290.0)
  let cooled = design_pfr(
    reaction,
    feed,
    2.0,
    thermal_mode=NonIsothermal,
    exchange=jacket,
  )
  assert_true(ad.outlet_temperature >= feed.temperature)
  assert_true(cooled.outlet_temperature <= ad.outlet_temperature)
  assert_true(thermal_margin(cooled.outlet_temperature, 400.0) > 0.0)
}

///|
test "solver diagnostics distinguish failure modes" {
  let failure = bisect_report(0.0, 1.0, fn(x : Double) { x * x + 1.0 })
  assert_eq(failure.status, BracketFailure)
  let success = bisect_report(0.0, 2.0, fn(x : Double) { x * x - 2.0 })
  assert_eq(success.status, Converged)
  let invalid = integrate_trapezoid_report(0.0, 1.0, 0, fn(x : Double) { x })
  assert_eq(invalid.status, InvalidRange)
  assert_true(integrate_trapezoid(1.0, 0.0, 10, fn(x : Double) { x }) < 0.0)
}
