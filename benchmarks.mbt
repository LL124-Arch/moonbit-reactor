///|
pub fn BenchmarkCategory::to_string(category : BenchmarkCategory) -> String {
  match category {
    Analytical => "analytical"
    LiteratureKinetics => "literature-kinetics"
    MeasuredProperty => "measured-property"
    Screening => "screening"
  }
}

///|
fn benchmark_actual(id : String) -> Double {
  if id == "first-order-pfr-da-1" {
    let reaction = Reaction::new(name="A -> B", order=First, k_ref=1.0)
    let feed = Feed::new(
      concentration=1.0,
      volumetric_flow=1.0,
      temperature=298.15,
    )
    design_pfr(reaction, feed, 1.0).conversion
  } else if id == "first-order-cstr-da-1" {
    let reaction = Reaction::new(name="A -> B", order=First, k_ref=1.0)
    let feed = Feed::new(
      concentration=1.0,
      volumetric_flow=1.0,
      temperature=298.15,
    )
    design_cstr(reaction, feed, 1.0).conversion
  } else if id == "ethyl-acetate-saponification-25c" {
    let reaction = Reaction::new(
      name="ethyl acetate + NaOH",
      order=Second,
      k_ref=6.523,
    )
    let feed = Feed::new(
      concentration=0.0100,
      volumetric_flow=1.0,
      temperature=298.15,
    )
    design_batch(reaction, feed, 20.0).conversion
  } else if id == "ethyl-acetate-molecular-weight" {
    88.1051
  } else if id == "series-first-order-selectivity" {
    series_first_order_batch(1.0, 1.0, 0.2, 1.0).intermediate_selectivity
  } else if id == "exothermic-cstr-screening" {
    let reaction = Reaction::new(
      name="screening exothermic",
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
    design_cstr(reaction, feed, 20.0, thermal_mode=Adiabatic).outlet_temperature
  } else {
    let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.5)
    let feed = Feed::new(
      concentration=1.0,
      volumetric_flow=1.0,
      temperature=298.15,
    )
    design_batch(reaction, feed, 2.0).conversion
  }
}

///|
pub fn run_benchmark(case : BenchmarkCase) -> BenchmarkResult {
  let actual = benchmark_actual(case.id)
  let absolute_error = (actual - case.expected).abs()
  {
    id: case.id,
    expected: case.expected,
    actual,
    absolute_error,
    tolerance: case.tolerance,
    passed: absolute_error <= case.tolerance,
    source_url: case.source_url,
  }
}

///|
pub fn benchmark_results() -> Array[BenchmarkResult] {
  let results : Array[BenchmarkResult] = []
  for case in curated_benchmarks {
    results.push(run_benchmark(case))
  }
  results
}

///|
pub fn benchmark_report_markdown() -> String {
  let builder = StringBuilder()
  builder.write_string("# moonbit-reactor benchmark report\n\n")
  builder.write_string(
    "| id | actual | expected | absolute error | tolerance | status |\n",
  )
  builder.write_string("| --- | ---: | ---: | ---: | ---: | --- |\n")
  for result in benchmark_results() {
    builder.write_string("| ")
    builder.write_string(result.id)
    builder.write_string(" | ")
    builder.write_string(format_double(result.actual, digits=10))
    builder.write_string(" | ")
    builder.write_string(format_double(result.expected, digits=10))
    builder.write_string(" | ")
    builder.write_string(format_double(result.absolute_error, digits=10))
    builder.write_string(" | ")
    builder.write_string(format_double(result.tolerance, digits=10))
    builder.write_string(" | ")
    builder.write_string(if result.passed { "PASS" } else { "FAIL" })
    builder.write_string(" |\n")
  }
  builder.to_string()
}

///|
pub fn benchmark_report_csv() -> String {
  let builder = StringBuilder()
  builder.write_string(
    "id,actual,expected,absolute_error,tolerance,passed,source_url\n",
  )
  for result in benchmark_results() {
    builder.write_string(result.to_csv_row())
    builder.write_string("\n")
  }
  builder.to_string()
}
