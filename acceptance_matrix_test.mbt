///|
test "zero order matrix" {
  let reaction = Reaction::new(name="zero", order=Zero, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  for volume in [0.0, 0.1, 1.0, 10.0, 100.0] {
    let pfr = design_pfr(reaction, feed, volume)
    let cstr = design_cstr(reaction, feed, volume)
    assert_true(pfr.conversion >= cstr.conversion)
    assert_true(pfr.conversion >= 0.0 && pfr.conversion < 1.0)
  }
}

///|
test "first order volume matrix" {
  let reaction = Reaction::new(name="first", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let points = pfr_profile(reaction, feed, 20.0, points=41)
  assert_eq(points.length(), 41)
  assert_true(profile_is_monotone(points))
  assert_true(points[40].conversion > 0.8)
}

///|
test "second order volume matrix" {
  let reaction = Reaction::new(name="second", order=Second, k_ref=0.1)
  let feed = Feed::new(
    concentration=2.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let volumes = linspace(0.0, 10.0, 31)
  let curve = pfr_conversion_curve(reaction, feed, volumes)
  assert_eq(curve.length(), volumes.length())
  assert_true(batch_curve_is_monotone(curve))
  assert_true(curve[0] == 0.0)
}

///|
test "temperature offset matrix" {
  let reaction = Reaction::new(
    name="temperature",
    order=First,
    k_ref=0.1,
    activation_energy=5000.0,
  )
  let base = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let cool = design_pfr(reaction, { ..base, temperature: 290.0 }, 2.0)
  let hot = design_pfr(reaction, { ..base, temperature: 310.0 }, 2.0)
  assert_true(hot.conversion > cool.conversion)
  assert_true(rate_temperature_ratio(reaction, 290.0, 310.0) > 1.0)
}

///|
test "thermal mode matrix" {
  let reaction = Reaction::new(
    name="thermal",
    order=First,
    k_ref=0.1,
    reaction_enthalpy=-5000.0,
  )
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
    heat_capacity_flow=1000.0,
  )
  let hx = HeatExchange::new(ua=500.0, coolant_temperature=290.0)
  let iso = design_pfr(reaction, feed, 5.0)
  let ad = design_pfr(reaction, feed, 5.0, thermal_mode=Adiabatic)
  let jacket = design_pfr(
    reaction,
    feed,
    5.0,
    thermal_mode=NonIsothermal,
    exchange=hx,
  )
  assert_true(ad.outlet_temperature >= iso.outlet_temperature)
  assert_true(jacket.outlet_temperature <= ad.outlet_temperature)
  assert_true(validate_design_point(jacket, feed).has_errors() == false)
}

///|
test "interval matrix encloses nominal" {
  let reaction = Reaction::new(name="interval", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  for volume in [0.0, 0.5, 2.0, 5.0] {
    let interval = propagate_interval(reaction, feed, volume, 0.2, 2.0)
    assert_true(interval_encloses_nominal(interval))
    assert_true(interval.minimum_conversion <= interval.maximum_conversion)
    assert_true(interval.minimum_temperature <= interval.maximum_temperature)
  }
}

///|
test "uncertainty sample matrix" {
  let reaction = Reaction::new(name="samples", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  for samples in [0, 1, 2, 5, 20] {
    let summary = uncertainty_summary(reaction, feed, 3.0, samples)
    assert_true(uncertainty_summary_is_ordered(summary))
    assert_eq(summary.samples, samples)
  }
}

///|
test "controller sample matrix" {
  let config = ControllerConfig::new(
    proportional=0.5,
    integral=0.1,
    derivative=0.05,
    minimum=0.0,
    maximum=1.0,
  )
  let initial = ControllerState::default()
  let mut state = initial
  for measurement in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0] {
    let step = controller_step(config, state, 1.0, measurement, 0.1)
    assert_true(step.output >= 0.0 && step.output <= 1.0)
    state = step.state
  }
  assert_true(state.previous_error <= 1.0)
}

///|
test "economic assumption matrix" {
  let reaction = Reaction::new(name="cost", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 2.0)
  for maintenance in [0.0, 0.05, 0.1] {
    let assumptions = {
      ..CostAssumptions::default(),
      maintenance_fraction: maintenance,
    }
    let cost = estimate_annual_cost(point, assumptions)
    assert_true(cost.total >= cost.capital)
    assert_true(cost_per_conversion(cost, point) > 0.0)
  }
}

///|
test "network stage matrix" {
  let reaction = Reaction::new(name="stages", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let stages : Array[ReactorStage] = [
    ReactorStage::cstr(volume=1.0),
    ReactorStage::pfr(volume=1.0),
    ReactorStage::batch(time=1.0),
  ]
  let result = analyze_train(reaction, feed, stages)
  assert_eq(result.stages.length(), 3)
  assert_true(final_stage_gain(result) >= 0.0)
  assert_true(train_peak_temperature(result) >= feed.temperature)
}

///|
test "report shape matrix" {
  let reaction = Reaction::new(name="reports", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 1.0)
  assert_true(design_point_to_csv_row(point).contains("PFR"))
  assert_true(design_points_to_csv([point]).contains("outlet_temperature"))
  assert_true(
    profile_summary(pfr_profile(reaction, feed, 1.0, points=3)).contains(
      "points=3",
    ),
  )
  assert_true(
    train_summary(
      analyze_train(reaction, feed, [ReactorStage::pfr(volume=1.0)]),
    ).contains("stages=1"),
  )
}

///|
test "physical conversion matrix" {
  for conversion in [-2.0, -0.1, 0.0, 0.2, 0.9, 1.0, 2.0] {
    let bounded = clamp_conversion(conversion)
    assert_true(bounded >= 0.0 && bounded < 1.0)
    assert_true(
      concentration_from_conversion(
        Feed::new(concentration=2.0, volumetric_flow=1.0, temperature=300.0),
        conversion,
      ) >=
      0.0,
    )
  }
}

///|
test "solver range matrix" {
  for steps in [-2, 0, 1, 2, 10] {
    let value = integrate_trapezoid(0.0, 1.0, steps, fn(x : Double) { x })
    assert_true(value >= 0.0)
  }
  assert_eq(
    integrate_trapezoid_report(0.0, 1.0, -1, fn(x : Double) { x }).status,
    InvalidRange,
  )
}

///|
test "safety window matrix" {
  let points : Array[ReactorSweepPoint] = [
    { volume: 0.0, conversion: 0.0, outlet_temperature: 300.0 },
    { volume: 1.0, conversion: 0.2, outlet_temperature: 310.0 },
    { volume: 2.0, conversion: 0.4, outlet_temperature: 330.0 },
  ]
  assert_eq(safety_counts(points, 320.0), (2, 1))
  assert_true(last_safe_sweep_point(points, 320.0) is Some(_))
  assert_true(first_unsafe_sweep_point(points, 320.0) is Some(_))
  assert_true(minimum_temperature_margin(points, 320.0) < 0.0)
}

///|
test "sampling matrix preserves endpoints" {
  for count in [1, 2, 3, 10, 50] {
    let values = linspace(-1.0, 1.0, count)
    if count > 1 {
      assert_true(values[0] == -1.0)
      assert_true(values[count - 1] == 1.0)
    }
  }
}

///|
test "metadata matrix is complete" {
  let cases = benchmark_cases()
  for case in cases {
    assert_true(benchmark_metadata_complete(case))
    assert_true(case.tolerance >= 0.0)
  }
  assert_true(benchmark_tolerances_valid(cases))
}
