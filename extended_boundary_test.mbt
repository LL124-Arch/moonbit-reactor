///|
test "integration boundaries and derivatives are stable" {
  assert_true(integrate_adaptive(0.0, 0.0, fn(x : Double) { x }).value == 0.0)
  assert_true(
    (integrate_simpson(0.0, 1.0, 8, fn(x : Double) { x * x }) - 1.0 / 3.0).abs() <
    1.0e-6,
  )
  assert_true(
    (integrate_rk4(0.0, 0.0, 1.0, 16, fn(_, y) { y + 1.0 }) -
    (2.718281828459045 - 1.0)).abs() <
    1.0e-3,
  )
  assert_true(
    (central_difference(2.0, fn(x : Double) { x * x }) - 4.0).abs() < 1.0e-3,
  )
  assert_true(
    (richardson_derivative(2.0, fn(x : Double) { x * x }) - 4.0).abs() < 1.0e-3,
  )
}

///|
test "sampling statistics handle empty and singleton arrays" {
  assert_eq(linspace(0.0, 1.0, 0).length(), 0)
  assert_eq(linspace(0.0, 1.0, 1), [0.0])
  assert_eq(midpoints([]).length(), 0)
  assert_eq(adjacent_differences([1.0]).length(), 0)
  assert_true(tabulated_trapezoid([], []) == 0.0)
  assert_true(root_mean_square([]) == 0.0)
  assert_true(mean_absolute_error([], []) == 0.0)
  assert_true(argmax([]) is None)
  assert_true(argmin([]) is None)
}

///|
test "advanced kinetics match closed forms" {
  assert_true(
    (first_order_concentration(1.0, 1.0, 1.0) - @math.exp(-1.0)).abs() < 1.0e-9,
  )
  assert_true((zero_order_concentration(1.0, 0.2, 2.0) - 0.6).abs() < 1.0e-9)
  assert_true(second_order_concentration(1.0, 1.0, 1.0) == 0.5)
  assert_true((first_order_time(1.0, 0.5) - natural_log(2.0)).abs() < 1.0e-8)
  assert_true(series_intermediate(1.0, 1.0, 1.0, 0.0) == 0.0)
  assert_true(series_product(1.0, 1.0, 1.0, 1.0) > 0.0)
  assert_true(estimate_order(1.0, 2.0, 1.0, 2.0) == 1.0)
  assert_true(half_life(1.0) > 0.0)
}

///|
test "safety screening identifies pressure and thermal limits" {
  assert_true(flow_velocity(1.0, 1.0) > 0.0)
  let velocity = flow_velocity(0.1, 0.1)
  let reynolds = reynolds_number(1000.0, velocity, 0.1, 0.001)
  assert_true(reynolds > 0.0)
  assert_true(
    pressure_drop(10.0, 0.1, 1000.0, velocity, friction_factor(reynolds)) > 0.0,
  )
  assert_true(safety_factor_ok(10.0, 2.0, 2.0))
  assert_true(conversion_target_is_well_conditioned(0.9))
  assert_true(!conversion_target_is_well_conditioned(0.999))
  assert_true(bisection_budget(0.0, 1.0, 1.0e-8) > 20)
}

///|
test "scenario matrices are reproducible" {
  let reaction = Reaction::new(name="scenario", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let base = OperatingScenario::isothermal(
    name="base",
    reaction~,
    feed~,
    volume=2.0,
  )
  let matrix = scenario_matrix(base, [0.9, 1.0, 1.1], [-5.0, 0.0, 5.0])
  assert_eq(matrix.length(), 9)
  assert_eq(feasible_scenario_count(matrix, 0.0, 400.0), 9)
  assert_true(best_scenario(matrix, 0.1, 400.0) is Some(_))
  assert_true(scenarios_to_csv(matrix).contains("name"))
}

///|
test "optimization frontiers preserve deterministic ordering" {
  let scores : Array[ObjectiveScore] = [
    {
      volume: 1.0,
      conversion: 0.4,
      temperature: 300.0,
      score: 0.4,
      feasible: true,
    },
    {
      volume: 2.0,
      conversion: 0.8,
      temperature: 310.0,
      score: 0.8,
      feasible: true,
    },
    {
      volume: 3.0,
      conversion: 0.7,
      temperature: 320.0,
      score: 0.7,
      feasible: true,
    },
  ]
  let frontier = pareto_frontier(scores)
  assert_true(frontier.length() >= 2)
  assert_true(dominates(scores[1], scores[2]))
  assert_true(score_precedes(scores[1], scores[0]))
  assert_true(closest_target(scores, 0.8, 2.0, 310.0) is Some(_))
}

///|
test "reporting functions include stable labels" {
  let sensitivity : SensitivityReport = {
    conversion_wrt_volume: 1.0,
    conversion_wrt_rate_constant: 2.0,
    conversion_wrt_temperature: 3.0,
    temperature_wrt_volume: 4.0,
    volume_wrt_target_conversion: 5.0,
  }
  assert_true(
    sensitivity_to_markdown(sensitivity).contains("conversion / volume"),
  )
  let summary : UncertaintySummary = {
    samples: 3,
    minimum: 0.1,
    maximum: 0.3,
    mean: 0.2,
    standard_deviation: 0.1,
    p05: 0.1,
    p50: 0.2,
    p95: 0.3,
  }
  assert_true(uncertainty_to_markdown(summary).contains("standard deviation"))
  let cost = estimate_annual_cost(
    design_pfr(
      Reaction::new(name="report", order=First, k_ref=0.1),
      Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
      1.0,
    ),
    CostAssumptions::default(),
  )
  assert_true(cost_to_markdown(cost).length() > 0)
}
