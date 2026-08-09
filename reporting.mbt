///|
pub(all) struct ReportColumn {
  name : String
  value : String
} derive(Debug, ToJson)

///|
pub fn format_double(x : Double, digits? : Int = 4) -> String {
  let scale = @math.pow(10.0, Double::from_int(digits.max(0)))
  let rounded = (x * scale).round() / scale
  rounded.to_string()
}

///|
pub fn DesignPoint::summary_rows(self : DesignPoint) -> Array[ReportColumn] {
  [
    { name: "kind", value: self.kind.to_string() },
    { name: "mode", value: self.thermal_mode.to_string() },
    { name: "volume", value: format_double(self.volume) },
    { name: "residence_time", value: format_double(self.residence_time) },
    { name: "conversion", value: format_double(self.conversion) },
    {
      name: "outlet_concentration",
      value: format_double(self.outlet_concentration),
    },
    {
      name: "outlet_temperature",
      value: format_double(self.outlet_temperature),
    },
    { name: "heat_removed", value: format_double(self.heat_removed) },
  ]
}

///|
pub fn DesignPoint::to_markdown(self : DesignPoint) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| field | value |\n")
  builder.write_string("| --- | ---: |\n")
  for row in self.summary_rows() {
    builder.write_string("| ")
    builder.write_string(row.name)
    builder.write_string(" | ")
    builder.write_string(row.value)
    builder.write_string(" |\n")
  }
  builder.to_string()
}

///|
pub fn sweep_to_csv(points : ArrayView[ReactorSweepPoint]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("volume,conversion,outlet_temperature\n")
  for point in points {
    builder.write_string(format_double(point.volume))
    builder.write_string(",")
    builder.write_string(format_double(point.conversion))
    builder.write_string(",")
    builder.write_string(format_double(point.outlet_temperature))
    builder.write_string("\n")
  }
  builder.to_string()
}

///|
pub fn network_to_markdown(result : NetworkResult) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| stage | kind | volume | conversion | temperature |\n")
  builder.write_string("| ---: | --- | ---: | ---: | ---: |\n")
  for i, stage in result.stages {
    builder.write_string("| ")
    builder.write_string((i + 1).to_string())
    builder.write_string(" | ")
    builder.write_string(stage.kind.to_string())
    builder.write_string(" | ")
    builder.write_string(format_double(stage.volume))
    builder.write_string(" | ")
    builder.write_string(format_double(stage.conversion))
    builder.write_string(" | ")
    builder.write_string(format_double(stage.outlet_temperature))
    builder.write_string(" |\n")
  }
  builder.write_string("\nfinal conversion: ")
  builder.write_string(format_double(result.final_conversion))
  builder.write_string("\n")
  builder.to_string()
}

///|
pub fn BenchmarkResult::to_csv_row(self : BenchmarkResult) -> String {
  let builder = StringBuilder::new()
  builder.write_string(self.id)
  builder.write_string(",")
  builder.write_string(format_double(self.actual, digits=10))
  builder.write_string(",")
  builder.write_string(format_double(self.expected, digits=10))
  builder.write_string(",")
  builder.write_string(format_double(self.absolute_error, digits=10))
  builder.write_string(",")
  builder.write_string(format_double(self.tolerance, digits=10))
  builder.write_string(",")
  builder.write_string(if self.passed { "true" } else { "false" })
  builder.write_string(",")
  builder.write_string(self.source_url)
  builder.to_string()
}
