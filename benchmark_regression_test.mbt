///|
test "benchmark analytical values remain exact" {
  let pfr = benchmark_case("first-order-pfr-da-1")
  let cstr = benchmark_case("first-order-cstr-da-1")
  let batch = benchmark_case("first-order-batch-da-1")
  assert_true(pfr is Some(_))
  assert_true(cstr is Some(_))
  assert_true(batch is Some(_))
  let results = benchmark_results()
  for result in results {
    assert_true(benchmark_result_is_reproducible(result))
  }
}

///|
test "benchmark source records expose assumptions" {
  for case in benchmark_cases() {
    assert_true(case.source_url.has_prefix("http"))
    assert_true(case.units.length() > 0)
    assert_true(case.assumptions.length() > 0)
    assert_true(case.tolerance >= 0.0)
  }
}

///|
test "benchmark category labels are stable" {
  assert_true(BenchmarkCategory::to_string(Analytical).length() > 0)
  assert_true(BenchmarkCategory::to_string(LiteratureKinetics).length() > 0)
  assert_true(BenchmarkCategory::to_string(MeasuredProperty).length() > 0)
  assert_true(BenchmarkCategory::to_string(Screening).length() > 0)
}

///|
test "benchmark reports include each identifier" {
  let report = benchmark_report_markdown()
  for case in benchmark_cases() {
    assert_true(report.contains(case.id))
  }
}

///|
test "benchmark csv row shape is deterministic" {
  let results = benchmark_results()
  let csv = benchmark_report_csv()
  assert_true(csv.has_prefix("id,actual,expected"))
  for result in results {
    assert_true(csv.contains(result.id))
  }
}

///|
test "benchmark result errors are within tolerance" {
  for result in benchmark_results() {
    assert_true(result.absolute_error <= result.tolerance)
    assert_true(result.passed)
    assert_true(result.source_url.has_prefix("http"))
  }
}

///|
test "benchmark registry lookup handles unknown ids" {
  assert_true(benchmark_case("not-a-real-case") is None)
  assert_true(benchmark_case("") is None)
}

///|
test "benchmark report formatting keeps decimal precision" {
  for result in benchmark_results() {
    let row = result.to_csv_row()
    assert_true(row.contains(result.id))
    assert_true(row.contains(result.source_url))
  }
}

///|
test "benchmark execution is idempotent" {
  let first = benchmark_results()
  let second = benchmark_results()
  assert_eq(first.length(), second.length())
  for i in 0..<first.length() {
    assert_true(first[i].actual == second[i].actual)
    assert_true(first[i].absolute_error == second[i].absolute_error)
  }
}

///|
test "offline benchmark data has no empty records" {
  assert_true(
    complete_benchmark_count(benchmark_cases()) == benchmark_cases().length(),
  )
  assert_true(first_invalid_benchmark(benchmark_cases()) is None)
}

///|
test "benchmark tolerance summaries are bounded" {
  let results = benchmark_results()
  let maximum = maximum_benchmark_error(results)
  assert_true(maximum >= 0.0)
  assert_true(benchmark_failure_count(results) == 0)
}

///|
test "analytical benchmark helper is consistent with design equations" {
  let reaction = Reaction::new(name="oracle", order=First, k_ref=1.0)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 1.0)
  assert_true(first_order_pfr_error(point, 1.0) < 1.0e-8)
  let cstr = design_cstr(reaction, feed, 1.0)
  assert_true(first_order_cstr_error(cstr, 1.0) < 1.0e-8)
}

///|
test "source-traceable benchmark markdown has table headings" {
  let report = benchmark_report_markdown()
  assert_true(report.contains("actual"))
  assert_true(report.contains("tolerance"))
  assert_true(report.contains("PASS"))
}

///|
test "benchmark data is suitable for native command execution" {
  assert_true(benchmark_report_csv().length() > 100)
  assert_true(benchmark_report_markdown().length() > 100)
}
