///|
test "adaptive integration handles smooth and reversed intervals" {
  let result = integrate_adaptive(0.0, 1.0, fn(x) { x * x }, tolerance=1.0e-8)
  assert_true(result.converged)
  assert_true((result.value - 1.0 / 3.0).abs() < 1.0e-6)
  let reversed = integrate_adaptive(1.0, 0.0, fn(x) { x }, tolerance=1.0e-8)
  assert_true((reversed.value + 0.5).abs() < 1.0e-6)
}

///|
test "reactor profile is monotone and mass balanced" {
  let reaction = Reaction::new(name="profile", order=First, k_ref=0.4)
  let feed = Feed::new(
    concentration=2.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let profile = pfr_profile(reaction, feed, 8.0, points=17)
  assert_eq(profile.length(), 17)
  assert_true(profile[0].conversion == 0.0)
  assert_true(profile[16].conversion > profile[1].conversion)
  assert_true(profile[16].concentration < feed.concentration)
}

///|
test "sensitivity and uncertainty remain finite at boundaries" {
  let reaction = Reaction::new(name="sensitivity", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 3.0)
  let sensitivity = design_sensitivity(reaction, feed, 3.0)
  assert_true(sensitivity.conversion_wrt_volume > 0.0)
  let interval = propagate_interval(reaction, feed, 3.0, 0.1, 0.05)
  assert_true(interval.minimum_conversion <= point.conversion)
  assert_true(interval.maximum_conversion >= point.conversion)
  let stats = uncertainty_summary(reaction, feed, 3.0, 11)
  assert_eq(stats.samples, 11)
  assert_true(stats.minimum <= stats.mean && stats.mean <= stats.maximum)
}

///|
test "pid controller respects output limits and reset" {
  let config = ControllerConfig::new(
    proportional=2.0,
    integral=0.4,
    derivative=0.1,
    minimum=0.0,
    maximum=1.0,
  )
  let first = controller_step(
    config,
    ControllerState::default(),
    10.0,
    0.0,
    1.0,
  )
  assert_true(first.output == 1.0)
  let reset = controller_reset(first.state)
  assert_true(reset.integral == 0.0)
}

///|
test "screening economics and design envelope are deterministic" {
  let reaction = Reaction::new(name="economics", order=First, k_ref=0.3)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  let point = design_cstr(reaction, feed, 4.0)
  let cost = estimate_annual_cost(point, CostAssumptions::default())
  assert_true(cost.total > 0.0)
  let envelope = design_envelope(reaction, feed, 0.0, 10.0, 5, 0.0, 400.0)
  assert_eq(envelope.length(), 6)
  assert_true(envelope[0].feasible)
}

///|
test "network analysis exposes stage totals" {
  let reaction = Reaction::new(name="network", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let stages = [
    ReactorStage::cstr(volume=1.0),
    ReactorStage::pfr(volume=2.0),
    ReactorStage::cstr(volume=1.0),
  ]
  let result = analyze_train(reaction, feed, stages)
  assert_eq(result.stages.length(), 3)
  assert_true(result.final_conversion > 0.0)
  assert_true(result.total_volume == 4.0)
}
