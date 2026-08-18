///|
/// A named operating scenario for repeatable screening.
pub(all) struct OperatingScenario {
  name : String
  reaction : Reaction
  feed : Feed
  volume : Double
  thermal_mode : ThermalMode
  exchange : HeatExchange?
} derive(Debug, ToJson)

///|
/// Construct an isothermal scenario.
pub fn OperatingScenario::isothermal(
  name~ : String,
  reaction~ : Reaction,
  feed~ : Feed,
  volume~ : Double,
) -> OperatingScenario {
  { name, reaction, feed, volume, thermal_mode: Isothermal, exchange: None }
}

///|
/// Construct an adiabatic scenario.
pub fn OperatingScenario::adiabatic(
  name~ : String,
  reaction~ : Reaction,
  feed~ : Feed,
  volume~ : Double,
) -> OperatingScenario {
  { name, reaction, feed, volume, thermal_mode: Adiabatic, exchange: None }
}

///|
/// Construct a jacketed scenario.
pub fn OperatingScenario::jacketed(
  name~ : String,
  reaction~ : Reaction,
  feed~ : Feed,
  volume~ : Double,
  exchange~ : HeatExchange,
) -> OperatingScenario {
  {
    name,
    reaction,
    feed,
    volume,
    thermal_mode: NonIsothermal,
    exchange: Some(exchange),
  }
}

///|
/// Evaluate a scenario with the declared thermal mode.
pub fn evaluate_scenario(scenario : OperatingScenario) -> DesignPoint {
  match scenario.exchange {
    Some(hx) =>
      design_pfr(
        scenario.reaction,
        scenario.feed,
        scenario.volume,
        thermal_mode=scenario.thermal_mode,
        exchange=hx,
      )
    None =>
      design_pfr(
        scenario.reaction,
        scenario.feed,
        scenario.volume,
        thermal_mode=scenario.thermal_mode,
      )
  }
}

///|
/// Evaluate several scenarios.
pub fn evaluate_scenarios(
  scenarios : ArrayView[OperatingScenario],
) -> Array[DesignPoint] {
  let result : Array[DesignPoint] = []
  for scenario in scenarios {
    result.push(evaluate_scenario(scenario))
  }
  result
}

///|
/// Find the hottest scenario.
pub fn hottest_scenario(
  scenarios : ArrayView[OperatingScenario],
) -> (String, Double)? {
  if scenarios.length() == 0 {
    None
  } else {
    let mut name = scenarios[0].name
    let mut temperature = evaluate_scenario(scenarios[0]).outlet_temperature
    for scenario in scenarios {
      let candidate = evaluate_scenario(scenario)
      if candidate.outlet_temperature > temperature {
        name = scenario.name
        temperature = candidate.outlet_temperature
      }
    }
    Some((name, temperature))
  }
}

///|
/// Find the highest-conversion scenario.
pub fn highest_conversion_scenario(
  scenarios : ArrayView[OperatingScenario],
) -> (String, Double)? {
  if scenarios.length() == 0 {
    None
  } else {
    let mut name = scenarios[0].name
    let mut conversion = evaluate_scenario(scenarios[0]).conversion
    for scenario in scenarios {
      let candidate = evaluate_scenario(scenario)
      if candidate.conversion > conversion {
        name = scenario.name
        conversion = candidate.conversion
      }
    }
    Some((name, conversion))
  }
}

///|
/// A temperature safety envelope for a scenario.
pub fn scenario_safety(
  scenario : OperatingScenario,
  maximum_temperature : Double,
) -> Bool {
  evaluate_scenario(scenario).outlet_temperature <= maximum_temperature
}

///|
/// A conversion target envelope for a scenario.
pub fn scenario_meets_conversion(
  scenario : OperatingScenario,
  minimum_conversion : Double,
) -> Bool {
  evaluate_scenario(scenario).conversion >= clamp_conversion(minimum_conversion)
}

///|
/// Evaluate a scenario across a volume grid.
pub fn scenario_volume_sweep(
  scenario : OperatingScenario,
  volumes : ArrayView[Double],
) -> Array[ReactorSweepPoint] {
  let result : Array[ReactorSweepPoint] = []
  for volume in volumes {
    let point = match scenario.exchange {
      Some(hx) =>
        design_pfr(
          scenario.reaction,
          scenario.feed,
          volume,
          thermal_mode=scenario.thermal_mode,
          exchange=hx,
        )
      None =>
        design_pfr(
          scenario.reaction,
          scenario.feed,
          volume,
          thermal_mode=scenario.thermal_mode,
        )
    }
    result.push({
      volume,
      conversion: point.conversion,
      outlet_temperature: point.outlet_temperature,
    })
  }
  result
}

///|
/// Compare two scenarios across conversion, temperature, and cost.
pub fn compare_scenarios(
  first : OperatingScenario,
  second : OperatingScenario,
  assumptions : CostAssumptions,
) -> Double {
  let first_point = evaluate_scenario(first)
  let second_point = evaluate_scenario(second)
  let first_cost = estimate_annual_cost(first_point, assumptions)
  let second_cost = estimate_annual_cost(second_point, assumptions)
  second_point.conversion -
  first_point.conversion -
  (second_cost.total - first_cost.total) / 1.0e6
}

///|
/// Apply a temperature offset to an operating scenario.
pub fn shift_scenario_temperature(
  scenario : OperatingScenario,
  offset : Double,
) -> OperatingScenario {
  {
    ..scenario,
    feed: { ..scenario.feed, temperature: scenario.feed.temperature + offset },
  }
}

///|
/// Apply a rate multiplier to an operating scenario.
pub fn scale_scenario_rate(
  scenario : OperatingScenario,
  multiplier : Double,
) -> OperatingScenario {
  {
    ..scenario,
    reaction: {
      ..scenario.reaction,
      k_ref: scenario.reaction.k_ref * multiplier.max(0.0),
    },
  }
}

///|
/// Apply a flow multiplier to an operating scenario.
pub fn scale_scenario_flow(
  scenario : OperatingScenario,
  multiplier : Double,
) -> OperatingScenario {
  {
    ..scenario,
    feed: {
      ..scenario.feed,
      volumetric_flow: scenario.feed.volumetric_flow * multiplier.max(0.0),
    },
  }
}

///|
/// Generate a Cartesian set of rate and temperature scenarios.
pub fn scenario_matrix(
  base : OperatingScenario,
  rate_multipliers : ArrayView[Double],
  temperature_offsets : ArrayView[Double],
) -> Array[OperatingScenario] {
  let result : Array[OperatingScenario] = []
  for rate in rate_multipliers {
    for offset in temperature_offsets {
      result.push(
        shift_scenario_temperature(scale_scenario_rate(base, rate), offset),
      )
    }
  }
  result
}

///|
/// Count scenarios that meet both safety and conversion targets.
pub fn feasible_scenario_count(
  scenarios : ArrayView[OperatingScenario],
  minimum_conversion : Double,
  maximum_temperature : Double,
) -> Int {
  scenarios.fold(init=0, fn(acc, scenario) {
    if scenario_meets_conversion(scenario, minimum_conversion) &&
      scenario_safety(scenario, maximum_temperature) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
/// Return a scenario's normalized performance score.
pub fn scenario_score(
  scenario : OperatingScenario,
  target_conversion : Double,
  maximum_temperature : Double,
) -> Double {
  let point = evaluate_scenario(scenario)
  let penalty = if point.outlet_temperature <= maximum_temperature {
    0.0
  } else {
    1.0
  }
  point.conversion / clamp_conversion(target_conversion).max(1.0e-12) - penalty
}

///|
/// Select the highest-scoring scenario.
pub fn best_scenario(
  scenarios : ArrayView[OperatingScenario],
  target_conversion : Double,
  maximum_temperature : Double,
) -> OperatingScenario? {
  if scenarios.length() == 0 {
    None
  } else {
    let mut best = scenarios[0]
    let mut score = scenario_score(best, target_conversion, maximum_temperature)
    for scenario in scenarios {
      let candidate = scenario_score(
        scenario, target_conversion, maximum_temperature,
      )
      if candidate > score {
        best = scenario
        score = candidate
      }
    }
    Some(best)
  }
}

///|
/// Build a scenario comparison CSV.
pub fn scenarios_to_csv(scenarios : ArrayView[OperatingScenario]) -> String {
  let mut output = "name,volume,conversion,temperature,rate\n"
  for scenario in scenarios {
    let point = evaluate_scenario(scenario)
    output = output +
      scenario.name +
      "," +
      format_double(point.volume) +
      "," +
      format_double(point.conversion) +
      "," +
      format_double(point.outlet_temperature) +
      "," +
      format_double(point.rate_at_outlet) +
      "\n"
  }
  output
}
