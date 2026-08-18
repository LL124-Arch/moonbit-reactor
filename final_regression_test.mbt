///|
test "final regression metrics" {
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let reaction = Reaction::new(name="final", order=First, k_ref=0.2)
  let point = design_pfr(reaction, feed, 2.0)
  assert_true(product_molar_flow(feed, point, 1.0) > 0.0)
  assert_true(outlet_flow(feed, point) < feed.volumetric_flow)
  assert_true(residence_time_ratio(point, point) == 1.0)
  assert_true(
    incremental_conversion_rate(point, design_pfr(reaction, feed, 3.0)) >= 0.0,
  )
}

///|
test "final regression thermodynamics" {
  assert_true(celsius_to_kelvin(-273.15) >= 1.0)
  assert_true(clamp_temperature(500.0, 280.0, 400.0) == 400.0)
  assert_true(clamp_rate_constant(-1.0, 0.0, 1.0) == 0.0)
  assert_true(thermal_window_ok(300.0, 280.0, 320.0))
  assert_true(
    heat_release_number(
      Reaction::new(name="h", order=First, k_ref=0.1, reaction_enthalpy=-1.0),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
    ) >
    0.0,
  )
}

///|
test "final regression reactor train" {
  let reaction = Reaction::new(name="train", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let stages = [ReactorStage::cstr(volume=1.0), ReactorStage::pfr(volume=1.0)]
  let result = analyze_thermal_train(reaction, feed, stages, Isothermal, None)
  assert_eq(result.stages.length(), 2)
  assert_true(validate_train(result).has_errors() == false)
  assert_true(train_to_csv(result).contains("reactor"))
}

///|
test "final regression report utilities" {
  assert_true(format_optional(None, 2) == "-")
  assert_true(format_optional(Some(1.234), 2).length() > 0)
  assert_true(has_standard_csv_header("a,b\n1,2", "a,b"))
  assert_true(report_contains_all("one two three", ["one", "three"]))
  assert_true(report_row_count("one\ntwo\nthree") == 3)
}

///|
test "final regression numerical sampling" {
  let samples = concentration_trajectory(1.0, 0.2, First, 5.0, 20)
  assert_eq(samples.length(), 20)
  assert_true(samples[0] >= samples[19])
  assert_true(
    tabulated_trapezoid(linspace(0.0, 1.0, 5), [0.0, 0.25, 0.5, 0.75, 1.0]) >
    0.0,
  )
}

///|
test "final regression lifecycle" {
  let reaction = Reaction::new(name="life", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_cstr(reaction, feed, 1.0)
  let report = validate_design_point(point, feed)
  assert_true(!report.has_errors())
  assert_true(
    estimate_annual_cost(point, CostAssumptions::default()).total > 0.0,
  )
  assert_true(screen_temperature(point, 400.0).safe)
  assert_true(first_order_condition_number(1.0) > 0.0)
}
