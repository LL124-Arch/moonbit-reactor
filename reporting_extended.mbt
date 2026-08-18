///|
/// Format a nullable numeric result for stable human-readable reports.
pub fn format_optional(value : Double?, digits : Int) -> String {
  match value {
    None => "-"
    Some(x) => format_double(x, digits~)
  }
}

///|
/// Render a sensitivity report as Markdown.
pub fn sensitivity_to_markdown(report : SensitivityReport) -> String {
  "| quantity | derivative |\n| --- | ---: |\n" +
  "| conversion / volume | " +
  format_double(report.conversion_wrt_volume) +
  " |\n" +
  "| conversion / rate constant | " +
  format_double(report.conversion_wrt_rate_constant) +
  " |\n" +
  "| conversion / temperature | " +
  format_double(report.conversion_wrt_temperature) +
  " |\n" +
  "| temperature / volume | " +
  format_double(report.temperature_wrt_volume) +
  " |\n" +
  "| volume / target conversion | " +
  format_double(report.volume_wrt_target_conversion) +
  " |\n"
}

///|
/// Render an uncertainty summary as Markdown.
pub fn uncertainty_to_markdown(summary : UncertaintySummary) -> String {
  "| statistic | value |\n| --- | ---: |\n" +
  "| samples | " +
  summary.samples.to_string() +
  " |\n" +
  "| minimum | " +
  format_double(summary.minimum) +
  " |\n" +
  "| p05 | " +
  format_double(summary.p05) +
  " |\n" +
  "| mean | " +
  format_double(summary.mean) +
  " |\n" +
  "| p50 | " +
  format_double(summary.p50) +
  " |\n" +
  "| p95 | " +
  format_double(summary.p95) +
  " |\n" +
  "| maximum | " +
  format_double(summary.maximum) +
  " |\n" +
  "| standard deviation | " +
  format_double(summary.standard_deviation) +
  " |\n"
}

///|
/// Render a cost estimate as Markdown.
pub fn cost_to_markdown(cost : CostEstimate) -> String {
  "| component | annualized cost |\n| --- | ---: |\n" +
  "| capital | " +
  format_double(cost.capital) +
  " |\n" +
  "| utilities | " +
  format_double(cost.utilities) +
  " |\n" +
  "| maintenance | " +
  format_double(cost.maintenance) +
  " |\n" +
  "| total | " +
  format_double(cost.total) +
  " |\n"
}

///|
/// Render an envelope table with feasibility reasons.
pub fn envelope_to_markdown(points : ArrayView[EnvelopePoint]) -> String {
  points.fold(
    init="| volume | conversion | temperature | feasible | reason |\n| ---: | ---: | ---: | :---: | --- |\n",
    fn(acc, point) {
      acc +
      "| " +
      format_double(point.volume) +
      " | " +
      format_double(point.conversion) +
      " | " +
      format_double(point.temperature) +
      " | " +
      point.feasible.to_string() +
      " | " +
      point.reason +
      " |\n"
    },
  )
}

///|
/// Render a controller trace as CSV.
pub fn controller_to_csv(trace : ArrayView[ControllerStep]) -> String {
  let header = "index,output,integral,previous_error,saturated\n"
  let mut index = 0
  let mut output = header
  for step in trace {
    output = output +
      index.to_string() +
      "," +
      format_double(step.output) +
      "," +
      format_double(step.state.integral) +
      "," +
      format_double(step.state.previous_error) +
      "," +
      step.saturated.to_string() +
      "\n"
    index = index + 1
  }
  output
}

///|
/// Render profile diagnostics as Markdown.
pub fn profile_summary(profile : ArrayView[ProfilePoint]) -> String {
  if profile.length() == 0 {
    "empty profile"
  } else {
    let first = profile[0]
    let last = profile[profile.length() - 1]
    "points=" +
    profile.length().to_string() +
    ", conversion=" +
    format_double(first.conversion) +
    ".." +
    format_double(last.conversion) +
    ", temperature=" +
    format_double(first.temperature) +
    ".." +
    format_double(last.temperature) +
    ", exposure=" +
    format_double(profile_rate_exposure(profile))
  }
}

///|
/// Render a train summary as Markdown.
pub fn train_summary(result : TrainResult) -> String {
  "stages=" +
  result.stages.length().to_string() +
  ", total volume=" +
  format_double(result.total_volume) +
  ", residence time=" +
  format_double(result.total_residence_time) +
  ", final conversion=" +
  format_double(result.final_conversion) +
  ", peak temperature=" +
  format_double(train_peak_temperature(result))
}

///|
/// Render validation messages with a stable severity prefix.
pub fn validation_to_markdown(report : ValidationReport) -> String {
  report.messages.fold(
    init="| level | field | message |\n| --- | --- | --- |\n",
    fn(acc, message) {
      acc +
      "| " +
      message.level.to_string() +
      " | " +
      message.field +
      " | " +
      message.message +
      " |\n"
    },
  )
}

///|
/// Render a benchmark result with an explicit status.
pub fn benchmark_result_to_markdown(result : BenchmarkResult) -> String {
  let status = if result.passed { "PASS" } else { "FAIL" }
  "| " +
  result.id +
  " | " +
  status +
  " | " +
  format_double(result.actual) +
  " | " +
  format_double(result.absolute_error) +
  " | " +
  format_double(result.tolerance) +
  " |\n"
}

///|
/// Render all benchmark results as a stable table.
pub fn benchmark_results_to_markdown(
  results : ArrayView[BenchmarkResult],
) -> String {
  results.fold(
    init="| id | status | actual | error | tolerance |\n| --- | --- | ---: | ---: | ---: |\n",
    fn(acc, result) { acc + benchmark_result_to_markdown(result) },
  )
}

///|
/// Render an objective surface as CSV.
pub fn objective_surface_to_csv(scores : ArrayView[ObjectiveScore]) -> String {
  scores.fold(init="volume,conversion,temperature,score,feasible\n", fn(
    acc,
    score,
  ) {
    acc +
    format_double(score.volume) +
    "," +
    format_double(score.conversion) +
    "," +
    format_double(score.temperature) +
    "," +
    format_double(score.score) +
    "," +
    score.feasible.to_string() +
    "\n"
  })
}

///|
/// Render a design point as a machine-readable CSV row.
pub fn design_point_to_csv_row(point : DesignPoint) -> String {
  point.kind.to_string() +
  "," +
  point.thermal_mode.to_string() +
  "," +
  format_double(point.volume) +
  "," +
  format_double(point.residence_time) +
  "," +
  format_double(point.conversion) +
  "," +
  format_double(point.outlet_concentration) +
  "," +
  format_double(point.outlet_temperature) +
  "," +
  format_double(point.heat_removed) +
  "," +
  format_double(point.rate_at_outlet) +
  "\n"
}

///|
/// Render a list of design points with a stable header.
pub fn design_points_to_csv(points : ArrayView[DesignPoint]) -> String {
  points.fold(
    init="kind,thermal_mode,volume,residence_time,conversion,outlet_concentration,outlet_temperature,heat_removed,rate_at_outlet\n",
    fn(acc, point) { acc + design_point_to_csv_row(point) },
  )
}
