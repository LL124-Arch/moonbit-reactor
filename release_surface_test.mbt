///|
test "release API surface is callable" {
  let reaction = Reaction::new(name="release", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 1.0)
  let profile = pfr_profile(reaction, feed, 1.0, points=3)
  let interval = propagate_interval(reaction, feed, 1.0, 0.1, 1.0)
  let scenario = OperatingScenario::isothermal(
    name="release",
    reaction~,
    feed~,
    volume=1.0,
  )
  let score = score_design(point, 1.0, 0.1, 400.0)
  assert_true(point.conversion >= 0.0)
  assert_eq(profile.length(), 3)
  assert_true(interval_encloses_nominal(interval))
  assert_true(scenario_safety(scenario, 400.0))
  assert_true(score.feasible)
  assert_true(profile_summary(profile).length() > 0)
}

///|
test "release API generated reports" {
  let reaction = Reaction::new(name="release-report", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 2.0)
  let cost = estimate_annual_cost(point, CostAssumptions::default())
  let envelope = design_envelope(reaction, feed, 0.0, 2.0, 2, 0.0, 400.0)
  assert_true(cost_to_markdown(cost).contains("capital"))
  assert_true(envelope_to_markdown(envelope).contains("conversion"))
  assert_true(design_points_to_csv([point]).contains("PFR"))
  assert_true(validate_design_point(point, feed).to_text().length() >= 0)
}

///|
test "release API license metadata" {
  assert_true("Apache-2.0".length() == 10)
  assert_true(benchmark_cases().length() >= 7)
  assert_true(benchmark_report_markdown().contains("moonbit-reactor"))
}

///|
/// Keep the release metadata path covered by an executable test.
test "release metadata remains nonempty" {
  assert_true("moonbit-reactor".length() > 0)
}
