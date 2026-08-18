///|
test "acceptance edge small rates" {
  let reaction = Reaction::new(name="small", order=First, k_ref=1.0e-12)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 1.0e-12)
  assert_true(point.conversion >= 0.0)
  assert_true(conversion_time_first_order(1.0e-12, 0.5) > 0.0)
  assert_true(levenspiel_ordinate(reaction, feed, 0.5) > 0.0)
}

///|
test "acceptance edge high conversion" {
  let reaction = Reaction::new(name="high", order=First, k_ref=10.0)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 100.0)
  assert_true(point.conversion < 1.0)
  assert_true(point.outlet_concentration >= 0.0)
  assert_true(conversion_target_is_well_conditioned(0.99))
}

///|
test "acceptance edge heat exchange" {
  let exchange = HeatExchange::new(ua=-1.0, coolant_temperature=300.0)
  assert_true(exchanger_duty(-1.0, 10.0, 5.0) >= 0.0)
  assert_true(required_ua(100.0, 10.0, 5.0) > 0.0)
  assert_true(jacket_heat_removal(exchange, 350.0, 300.0, 1.0) >= 0.0)
}

///|
test "acceptance edge parallel kinetics" {
  let split = parallel_split(1.0, 0.2, 0.3, First, Second)
  assert_true(split.0 >= 0.0)
  assert_true(split.1 >= 0.0)
  assert_true(parallel_selectivity(split.0, split.1) >= 0.0)
}

///|
test "acceptance edge validation" {
  let invalid = Feed::new(
    concentration=-1.0,
    volumetric_flow=-1.0,
    temperature=-1.0,
  )
  assert_true(validate_feed(invalid).has_errors())
  assert_true(validate_feed_window(invalid, 280.0, 320.0).has_errors())
  assert_true(validate_volume_grid(1.0, 0.0, -1).has_errors())
}

///|
test "acceptance edge search" {
  let config = SearchConfig::new(minimum=0.0, maximum=1.0, steps=10)
  let scores = evaluate_grid(config, fn(x : Double) { (x - 0.5) * (x - 0.5) })
  assert_eq(scores.length(), 11)
  assert_true(minimum_scalar(scores) is Some(_))
  assert_true(maximum_scalar(scores) is Some(_))
}

///|
test "acceptance edge derivatives" {
  assert_true(
    (central_difference(0.0, fn(x : Double) { x + 1.0 }) - 1.0).abs() < 1.0e-6,
  )
  assert_true(
    (richardson_derivative(0.0, fn(x : Double) { x + 1.0 }) - 1.0).abs() <
    1.0e-6,
  )
  assert_true(
    relative_rate_error(
      Reaction::new(name="d", order=First, k_ref=1.0),
      1.0,
      300.0,
      1.0,
    ) <
    1.0e-9,
  )
}

///|
test "acceptance edge data reduction" {
  let values = [1.0, 2.0, 3.0, 4.0]
  assert_true(weighted_mean(values, [1.0, 1.0, 1.0, 1.0]) == 2.5)
  assert_true(root_mean_square(values) > 0.0)
  assert_true(maximum_absolute_error(values, [1.0, 2.0, 2.0, 5.0]) == 1.0)
  assert_eq(argmax(values), Some(3))
  assert_eq(argmin(values), Some(0))
}
