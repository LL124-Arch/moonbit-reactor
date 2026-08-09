///|
fn assert_close(
  actual : Double,
  expected : Double,
  tolerance : Double,
) -> Unit raise {
  assert_true((actual - expected).abs() <= tolerance)
}

///|
test "first order CSTR and PFR match textbook equations" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.5)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  let cstr = design_cstr(reaction, feed, 4.0)
  let pfr = design_pfr(reaction, feed, 4.0)
  assert_close(cstr.conversion, 0.5, 1.0e-8)
  assert_close(pfr.conversion, 0.6321205588, 1.0e-7)
  assert_true(pfr.conversion > cstr.conversion)
}

///|
test "second order CSTR root stays inside physical conversion range" {
  let reaction = Reaction::new(name="A + B -> C", order=Second, k_ref=0.25)
  let feed = Feed::new(
    concentration=2.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_cstr(reaction, feed, 3.0)
  assert_true(point.conversion > 0.0)
  assert_true(point.conversion < 1.0)
  assert_true(point.outlet_concentration >= 0.0)
}

///|
test "batch reactor reaches same first-order conversion at equal time as PFR" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=310.0,
  )
  let batch = design_batch(reaction, feed, 5.0)
  let pfr = design_pfr(reaction, feed, 5.0)
  assert_close(batch.conversion, pfr.conversion, 1.0e-8)
}

///|
test "Arrhenius rate increases with temperature for positive activation energy" {
  let reaction = Reaction::new(
    name="temperature sensitive",
    order=First,
    k_ref=0.1,
    activation_energy=50000.0,
    reference_temperature=300.0,
  )
  assert_true(reaction.rate_constant(340.0) > reaction.rate_constant(300.0))
}

///|
test "bisection finds a simple root" {
  let root = bisect(0.0, 2.0, fn(x) { x * x - 2.0 })
  assert_true(root.converged)
  assert_close(root.root, 1.41421356, 1.0e-6)
}

///|
test "trapezoid integration is adequate for smooth design curves" {
  let area = integrate_trapezoid(0.0, 1.0, 200, fn(x) { x * x })
  assert_close(area, 0.333333, 1.0e-4)
}

///|
test "adiabatic exothermic CSTR raises outlet temperature" {
  let reaction = Reaction::new(
    name="exothermic",
    order=First,
    k_ref=0.03,
    reaction_enthalpy=-50000.0,
  )
  let feed = Feed::new(
    concentration=0.8,
    volumetric_flow=1.0,
    temperature=315.0,
    heat_capacity_flow=5000.0,
  )
  let point = design_cstr(reaction, feed, 20.0, thermal_mode=Adiabatic)
  assert_true(point.outlet_temperature > feed.temperature)
}

///|
test "jacketed non-isothermal mode pulls temperature toward coolant" {
  let reaction = Reaction::new(
    name="cooled reaction",
    order=First,
    k_ref=0.05,
    reaction_enthalpy=-80000.0,
  )
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=330.0,
    heat_capacity_flow=6000.0,
  )
  let hx = HeatExchange::new(ua=3000.0, coolant_temperature=300.0)
  let ad = design_cstr(reaction, feed, 15.0, thermal_mode=Adiabatic)
  let cooled = design_cstr(
    reaction,
    feed,
    15.0,
    thermal_mode=NonIsothermal,
    exchange=hx,
  )
  assert_true(cooled.outlet_temperature < ad.outlet_temperature)
}

///|
test "volume solvers hit requested conversion" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let vc = required_cstr_volume(reaction, feed, 0.6)
  let vp = required_pfr_volume(reaction, feed, 0.6)
  assert_close(design_cstr(reaction, feed, vc).conversion, 0.6, 1.0e-5)
  assert_close(design_pfr(reaction, feed, vp).conversion, 0.6, 1.0e-5)
}

///|
test "sweep keeps endpoints and monotonic trend" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.1)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let points = sweep_pfr(reaction, feed, 10.0, 6)
  assert_eq(points.length(), 6)
  assert_close(points[0].volume, 0.0, 1.0e-12)
  assert_close(points[5].volume, 10.0, 1.0e-12)
  assert_true(points[5].conversion > points[1].conversion)
}

///|
test "included example cases produce usable positive values" {
  let cstr = ethyl_acetate_saponification()
  let series = first_order_series_example()
  let boundary = exothermic_cstr_boundary()
  assert_true(cstr.conversion > 0.0)
  assert_true(series > 0.0)
  assert_true(boundary.max_safe_volume > 0.0)
}

///|
test "validation report catches invalid feed and reaction inputs" {
  let reaction = Reaction::new(name="", order=First, k_ref=0.0)
  let feed = Feed::new(
    concentration=-1.0,
    volumetric_flow=0.0,
    temperature=-2.0,
  )
  let report = validate_design_inputs(reaction, feed, -1.0)
  assert_true(report.has_errors())
  assert_true(report.count(Error) >= 4)
  assert_true(report.count(Warning) >= 1)
}

///|
test "reactor train improves conversion over one CSTR at same volume" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let train = equal_volume_cstr_train(4, 10.0)
  let network = run_network(reaction, feed, train)
  let single = design_cstr(reaction, feed, 10.0)
  assert_true(network.final_conversion > single.conversion)
  assert_eq(network.stages.length(), 4)
}

///|
test "markdown and csv reports include stable headers" {
  let point = ethyl_acetate_saponification()
  let md = point.to_markdown()
  let sweep = sweep_cstr(
    Reaction::new(name="A -> B", order=First, k_ref=0.1),
    Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0),
    5.0,
    3,
  )
  let csv = sweep_to_csv(sweep)
  assert_true(md.contains("| field | value |"))
  assert_true(csv.contains("volume,conversion,outlet_temperature"))
}

///|
test "grid optimizer returns feasible reactor choice" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.15)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let result = minimize_volume_for_conversion(
    reaction,
    feed,
    SearchRange::new(min=0.0, max=30.0, steps=61),
    0.8,
  )
  assert_true(result.feasible)
  assert_true(result.volume > 0.0)
  assert_true(result.conversion >= 0.8)
}

///|
test "engineering metrics preserve design point identities" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 4.0)
  assert_true(nearly_equal(space_time(feed, point.volume), 2.0))
  assert_true(
    nearly_equal(point.residence_time, residence_time(feed, point.volume)),
  )
  assert_true(
    nearly_equal(
      yield_from_conversion_selectivity(point.conversion, 1.0),
      point.conversion,
    ),
  )
  assert_true(
    nearly_equal(
      conversion_from_concentration(feed, point.outlet_concentration),
      point.conversion,
    ),
  )
  assert_true(conversion_is_physical(point.conversion))
}

///|
test "boundary cases remain physical" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  assert_eq(design_pfr(reaction, feed, 0.0).conversion, 0.0)
  assert_true(design_pfr(reaction, feed, 1.0e9).conversion < 1.0)
  assert_eq(sweep_pfr(reaction, feed, 5.0, 0).length(), 0)
  assert_eq(sweep_pfr(reaction, feed, 5.0, 1).length(), 1)
}

///|
test "solver report distinguishes bracket failures" {
  let failure = bisect_report(0.0, 1.0, fn(x) { x * x + 1.0 })
  assert_eq(failure.status, BracketFailure)
  let success = bisect_report(0.0, 2.0, fn(x) { x * x - 2.0 })
  assert_eq(success.status, Converged)
  assert_close(success.root, 1.41421356, 1.0e-6)
}

///|
test "solver report handles iteration and integration boundaries" {
  let limited = bisect_report(0.0, 2.0, fn(x) { x * x - 2.0 }, settings={
    tolerance: 1.0e-20,
    max_iterations: 1,
  })
  assert_eq(limited.status, IterationLimit)
  let invalid = integrate_trapezoid_report(0.0, 1.0, 0, fn(x) { x })
  assert_eq(invalid.status, InvalidRange)
  let reversed = integrate_trapezoid_report(1.0, 0.0, 100, fn(x) { x })
  assert_eq(reversed.status, Converged)
  assert_true(reversed.root < 0.0)
}

///|
test "reversible first-order rate vanishes at equilibrium" {
  let model : ReversibleFirstOrder = {
    forward_rate: 0.4,
    reverse_rate: 0.2,
    equilibrium_concentration: 2.0,
  }
  assert_close(reversible_first_order_rate(model, 1.0, 2.0), 0.0, 1.0e-12)
  assert_true(reversible_first_order_rate(model, 1.0, 1.0) > 0.0)
}

///|
test "series intermediate selectivity falls after its peak" {
  let early = series_first_order_batch(1.0, 0.2, 1.0, 1.0)
  let late = series_first_order_batch(1.0, 0.2, 1.0, 8.0)
  assert_true(early.intermediate_concentration > 0.0)
  assert_true(late.product_concentration > early.product_concentration)
  assert_true(late.intermediate_selectivity < early.intermediate_selectivity)
}

///|
test "parallel products partition the first-order rate" {
  let result = parallel_first_order_rates(2.0, 0.3, 0.2)
  assert_true(result.product_a_rate > 0.0)
  assert_true(result.product_b_rate > 0.0)
  assert_close(
    result.product_a_selectivity + result.product_b_selectivity,
    1.0,
    1.0e-12,
  )
}

///|
test "benchmark registry carries source metadata" {
  let cases = benchmark_cases()
  assert_true(cases.length() >= 7)
  for benchmark in cases {
    assert_true(benchmark.source.length() > 0)
    assert_true(benchmark.source_url.has_prefix("https://"))
    assert_true(benchmark.units.length() > 0)
    assert_true(benchmark.assumptions.length() > 0)
    assert_true(benchmark.tolerance > 0.0)
  }
}

///|
test "analytical and measured benchmark cases pass offline" {
  let pfr_case = benchmark_case("first-order-pfr-da-1")
  let saponification_case = benchmark_case("ethyl-acetate-saponification-25c")
  match pfr_case {
    None => fail("missing PFR benchmark")
    Some(case) => assert_true(run_benchmark(case).passed)
  }
  match saponification_case {
    None => fail("missing saponification benchmark")
    Some(case) => assert_true(run_benchmark(case).passed)
  }
  let report = benchmark_report_markdown()
  assert_true(report.contains("first-order-pfr-da-1"))
  assert_true(report.contains("ethyl-acetate-saponification-25c"))
  assert_true(benchmark_report_csv().contains("absolute_error"))
}

///|
test "all curated benchmark outputs pass their declared tolerance" {
  for result in benchmark_results() {
    assert_true(result.passed)
  }
}

///|
test "reverse root ranges are invalid" {
  let report = bisect_report(2.0, 0.0, fn(x) { x - 1.0 })
  assert_eq(report.status, InvalidRange)
}

///|
test "nan root endpoints are invalid" {
  let report = bisect_report(0.0 / 0.0, 1.0, fn(x) { x })
  assert_eq(report.status, InvalidRange)
}

///|
test "invalid concentration conversion returns zero" {
  let feed = Feed::new(
    concentration=0.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  assert_eq(conversion_from_concentration(feed, 0.5), 0.0)
}

///|
test "reaction rate clamps negative concentration" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  assert_eq(reaction.rate(-1.0, 300.0), 0.0)
}

///|
test "parallel zero rates return zero selectivity" {
  let result = parallel_first_order_rates(1.0, 0.0, 0.0)
  assert_eq(result.product_a_rate, 0.0)
  assert_eq(result.product_b_rate, 0.0)
  assert_eq(result.product_a_selectivity, 0.0)
  assert_eq(result.product_b_selectivity, 0.0)
}

///|
test "series zero time has no products" {
  let result = series_first_order_batch(1.0, 1.0, 0.2, 0.0)
  assert_eq(result.intermediate_concentration, 0.0)
  assert_eq(result.product_concentration, 0.0)
  assert_eq(result.intermediate_selectivity, 0.0)
}

///|
test "series equal rates remain finite" {
  let result = series_first_order_batch(1.0, 0.5, 0.5, 2.0)
  assert_true(result.intermediate_concentration > 0.0)
  assert_true(result.product_concentration > 0.0)
  assert_true(result.intermediate_selectivity < 1.0)
}

///|
test "negative reaction rates are bounded" {
  let result = series_first_order_batch(1.0, -1.0, -0.2, 2.0)
  assert_eq(result.intermediate_concentration, 0.0)
  assert_eq(result.product_concentration, 0.0)
}

///|
test "empty network preserves feed state" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let result = run_network(reaction, feed, [])
  assert_eq(result.stages.length(), 0)
  assert_eq(result.final_conversion, 0.0)
  assert_eq(result.final_concentration, 1.0)
}

///|
test "zero-stage train still has a usable stage count" {
  assert_eq(equal_volume_cstr_train(0, 10.0).length(), 1)
  assert_eq(equal_volume_pfr_train(-2, 10.0).length(), 1)
}
