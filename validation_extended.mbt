///|
/// Validate a temperature interval before a design sweep.
pub fn validate_temperature_interval(
  minimum : Double,
  maximum : Double,
) -> ValidationReport {
  let report = ValidationReport::new()
  if minimum <= 0.0 {
    report.push(Error, "minimum_temperature", "temperature must be positive")
  } else if minimum > maximum {
    report.push(Error, "temperature_interval", "minimum exceeds maximum")
  } else {
    report
  }
}

///|
/// Validate a volume grid.
pub fn validate_volume_grid(
  minimum : Double,
  maximum : Double,
  points : Int,
) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if minimum < 0.0 {
    report.push(Error, "minimum_volume", "volume must be non-negative")
  } else {
    report
  }
  let report = if maximum < minimum {
    report.push(Error, "maximum_volume", "maximum must not be below minimum")
  } else {
    report
  }
  if points < 1 {
    report.push(Error, "points", "at least one point is required")
  } else {
    report
  }
}

///|
/// Validate controller sampling settings.
pub fn validate_controller_settings(
  config : ControllerConfig,
  dt : Double,
  steps : Int,
) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if !config.validate() {
    report.push(Error, "controller", "invalid gains or limits")
  } else {
    report
  }
  let report = if dt <= 0.0 {
    report.push(Error, "dt", "time step must be positive")
  } else {
    report
  }
  if steps < 1 {
    report.push(Error, "steps", "at least one step is required")
  } else {
    report
  }
}

///|
/// Validate that a numerical tolerance is useful and finite.
pub fn validate_tolerance(
  tolerance : Double,
  maximum_depth : Int,
) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if tolerance <= 0.0 {
    report.push(Error, "tolerance", "tolerance must be positive")
  } else {
    report
  }
  if maximum_depth < 1 {
    report.push(Error, "maximum_depth", "depth must be positive")
  } else {
    report
  }
}

///|
/// Validate a feed against a named operating window.
pub fn validate_feed_window(
  feed : Feed,
  minimum_temperature : Double,
  maximum_temperature : Double,
) -> ValidationReport {
  let report = validate_feed(feed)
  let report = if !thermal_window_ok(
      feed.temperature,
      minimum_temperature,
      maximum_temperature,
    ) {
    report.push(
      Warning,
      "temperature",
      "feed temperature is outside the operating window",
    )
  } else {
    report
  }
  if feed.heat_capacity_flow <= 0.0 {
    report.push(
      Error,
      "heat_capacity_flow",
      "heat capacity flow must be positive",
    )
  } else {
    report
  }
}

///|
/// Validate a reaction for a stated design temperature.
pub fn validate_reaction_temperature(
  reaction : Reaction,
  temperature : Double,
) -> ValidationReport {
  let report = validate_reaction(reaction)
  let report = if temperature <= 0.0 {
    report.push(Error, "temperature", "temperature must be positive")
  } else {
    report
  }
  if reaction.reference_temperature <= 0.0 {
    report.push(
      Error,
      "reference_temperature",
      "reference temperature must be positive",
    )
  } else {
    report
  }
}

///|
/// Validate a candidate design point.
pub fn validate_design_point(
  point : DesignPoint,
  feed : Feed,
) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if point.volume < 0.0 {
    report.push(Error, "volume", "volume must be non-negative")
  } else {
    report
  }
  let report = if !design_point_is_physical(point, feed) {
    report.push(Error, "physical", "design point violates physical bounds")
  } else {
    report
  }
  if point.rate_at_outlet < -1.0e-9 {
    report.push(Error, "rate", "outlet rate must be non-negative")
  } else {
    report
  }
}

///|
/// Validate every point in a reactor sweep.
pub fn validate_sweep(
  points : ArrayView[ReactorSweepPoint],
  feed : Feed,
) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if feed.concentration < 0.0 {
    report.push(Error, "feed", "feed concentration must be non-negative")
  } else {
    report
  }
  let report = if !sweep_is_sorted(points) {
    report.push(Error, "volume", "sweep is not sorted")
  } else {
    report
  }
  for point in points {
    let report = if point.conversion < 0.0 || point.conversion >= 1.0 {
      report.push(Error, "conversion", "sweep conversion is outside bounds")
    } else {
      report
    }
    if point.outlet_temperature <= 0.0 || point.conversion < 0.0 {
      return report.push(Error, "state", "sweep state is non-physical")
    }
    ignore(report)
  }
  report
}

///|
/// Check whether a benchmark result meets its declared tolerance.
pub fn benchmark_result_is_reproducible(result : BenchmarkResult) -> Bool {
  result.passed && result.absolute_error <= result.tolerance
}

///|
/// Count benchmark failures.
pub fn benchmark_failure_count(results : ArrayView[BenchmarkResult]) -> Int {
  results.fold(init=0, fn(acc, result) {
    if result.passed {
      acc
    } else {
      acc + 1
    }
  })
}

///|
/// Find the largest benchmark error.
pub fn maximum_benchmark_error(results : ArrayView[BenchmarkResult]) -> Double {
  results.fold(init=0.0, fn(acc, result) { acc.max(result.absolute_error) })
}

///|
/// Check that benchmark metadata is complete.
pub fn benchmark_metadata_complete(case : BenchmarkCase) -> Bool {
  case.id.length() > 0 &&
  case.title.length() > 0 &&
  case.source.length() > 0 &&
  case.source_url.has_prefix("http") &&
  case.units.length() > 0 &&
  case.assumptions.length() > 0
}

///|
/// Count metadata-complete benchmark cases.
pub fn complete_benchmark_count(cases : ArrayView[BenchmarkCase]) -> Int {
  cases.fold(init=0, fn(acc, case) {
    if benchmark_metadata_complete(case) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
/// Validate all declared benchmark tolerances.
pub fn benchmark_tolerances_valid(cases : ArrayView[BenchmarkCase]) -> Bool {
  for case in cases {
    if case.tolerance < 0.0 || !benchmark_metadata_complete(case) {
      return false
    }
  }
  true
}

///|
/// Return the first invalid benchmark id.
pub fn first_invalid_benchmark(cases : ArrayView[BenchmarkCase]) -> String? {
  for case in cases {
    if !benchmark_metadata_complete(case) {
      return Some(case.id)
    }
  }
  None
}

///|
/// Check whether a report contains the standard CSV header.
pub fn has_standard_csv_header(report : String, header : String) -> Bool {
  report.has_prefix(header)
}

///|
/// Validate a stable report row count.
pub fn report_row_count(report : String) -> Int {
  report
  .split("\n")
  .fold(init=0, fn(acc, row) { if row.length() == 0 { acc } else { acc + 1 } })
}

///|
/// Check a text report for required labels.
pub fn report_contains_all(report : String, labels : ArrayView[String]) -> Bool {
  for label in labels {
    if !report.contains(label) {
      return false
    }
  }
  true
}

///|
/// Check that a conversion interval encloses its nominal point.
pub fn interval_encloses_nominal(interval : ConversionInterval) -> Bool {
  interval.minimum_conversion <= interval.nominal_conversion &&
  interval.nominal_conversion <= interval.maximum_conversion
}

///|
/// Check that an uncertainty summary is ordered and non-negative.
pub fn uncertainty_summary_is_ordered(summary : UncertaintySummary) -> Bool {
  summary.samples >= 0 &&
  summary.minimum <= summary.p05 &&
  summary.p05 <= summary.p50 &&
  summary.p50 <= summary.p95 &&
  summary.p95 <= summary.maximum &&
  summary.standard_deviation >= 0.0
}

///|
/// Validate a train's aggregate volume and conversion.
pub fn validate_train(result : TrainResult) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if result.total_volume < 0.0 {
    report.push(Error, "total_volume", "total volume must be non-negative")
  } else {
    report
  }
  let report = if result.final_conversion < 0.0 ||
    result.final_conversion >= 1.0 {
    report.push(Error, "final_conversion", "final conversion is outside bounds")
  } else {
    report
  }
  if result.total_residence_time < 0.0 {
    report.push(Error, "residence_time", "residence time must be non-negative")
  } else {
    report
  }
}
