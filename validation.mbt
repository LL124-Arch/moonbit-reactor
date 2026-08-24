///|
pub(all) enum ValidationLevel {
  Info
  Warning
  Error
} derive(Debug, Eq, ToJson)

///|
pub(all) struct ValidationMessage {
  level : ValidationLevel
  field : String
  message : String
} derive(Debug, ToJson)

///|
pub(all) struct ValidationReport {
  messages : Array[ValidationMessage]
} derive(Debug, ToJson)

///|
pub fn ValidationReport::new() -> ValidationReport {
  { messages: [] }
}

///|
pub fn ValidationReport::push(
  self : ValidationReport,
  level : ValidationLevel,
  field : String,
  message : String,
) -> ValidationReport {
  let messages = self.messages.copy()
  messages.push({ level, field, message })
  { messages, }
}

///|
pub fn ValidationReport::has_errors(self : ValidationReport) -> Bool {
  for message in self.messages {
    if message.level == Error {
      break true
    }
  } nobreak {
    false
  }
}

///|
pub fn ValidationReport::count(
  self : ValidationReport,
  level : ValidationLevel,
) -> Int {
  for i = 0, n = 0; i < self.messages.length(); i = i + 1 {
    let message = self.messages[i]
    if message.level == level {
      continue i + 1, n + 1
    } else {
      continue i + 1, n
    }
  } nobreak {
    n
  }
}

///|
pub fn validate_reaction(reaction : Reaction) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if reaction.name.length() == 0 {
    report.push(Warning, "name", "reaction name is empty")
  } else {
    report
  }
  let report = if reaction.k_ref <= 0.0 {
    report.push(Error, "k_ref", "rate constant must be positive")
  } else {
    report
  }
  let report = if reaction.reference_temperature <= 0.0 {
    report.push(Error, "reference_temperature", "temperature must use Kelvin")
  } else {
    report
  }
  if reaction.activation_energy < 0.0 {
    report.push(
      Warning,
      "activation_energy",
      "negative activation energy is unusual",
    )
  } else {
    report
  }
}

///|
pub fn validate_feed(feed : Feed) -> ValidationReport {
  let report = ValidationReport::new()
  let report = if feed.concentration <= 0.0 {
    report.push(Error, "concentration", "feed concentration must be positive")
  } else {
    report
  }
  let report = if feed.volumetric_flow <= 0.0 {
    report.push(Error, "volumetric_flow", "volumetric flow must be positive")
  } else {
    report
  }
  let report = if feed.temperature <= 0.0 {
    report.push(Error, "temperature", "temperature must use Kelvin")
  } else {
    report
  }
  if feed.heat_capacity_flow <= 0.0 {
    report.push(
      Warning,
      "heat_capacity_flow",
      "non-positive heat-capacity flow will be guarded numerically",
    )
  } else {
    report
  }
}

///|
pub fn validate_design_inputs(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
) -> ValidationReport {
  let r = validate_reaction(reaction)
  let f = validate_feed(feed)
  let messages = r.messages.copy()
  for message in f.messages {
    messages.push(message)
  }
  let report = { messages, }
  if volume < 0.0 {
    report.push(
      Error,
      "volume",
      "reactor volume or batch time proxy must be non-negative",
    )
  } else {
    report
  }
}

///|
pub fn ValidationLevel::to_string(level : ValidationLevel) -> String {
  match level {
    Info => "info"
    Warning => "warning"
    Error => "error"
  }
}

///|
pub fn ValidationMessage::to_line(self : ValidationMessage) -> String {
  "\{self.level.to_string()}:\{self.field}:\{self.message}"
}

///|
pub fn ValidationReport::to_text(self : ValidationReport) -> String {
  if self.messages.length() == 0 {
    "ok"
  } else {
    let builder = StringBuilder()
    for i, message in self.messages {
      if i > 0 {
        builder.write_string("\n")
      }
      builder.write_string(message.to_line())
    }
    builder.to_string()
  }
}
