///|
/// Run a typed reactor train, passing each outlet to the next stage.
pub fn analyze_train(
  reaction : Reaction,
  feed : Feed,
  stages : ArrayView[ReactorStage],
) -> TrainResult {
  let results : Array[DesignPoint] = []
  let mut current_feed = feed
  let mut total_volume = 0.0
  let mut total_time = 0.0
  for stage in stages {
    let point = run_train_stage(reaction, current_feed, stage)
    results.push(point)
    total_volume = total_volume + point.volume
    total_time = total_time + point.residence_time
    current_feed = {
      ..current_feed,
      concentration: point.outlet_concentration,
      temperature: point.outlet_temperature,
    }
  }
  let final_conversion = if feed.concentration <= 1.0e-12 {
    0.0
  } else {
    clamp_conversion(1.0 - current_feed.concentration / feed.concentration)
  }
  {
    stages: results,
    final_conversion,
    total_volume,
    total_residence_time: total_time,
  }
}

///|
/// Run a train with a shared thermal mode and optional jacket.
pub fn analyze_thermal_train(
  reaction : Reaction,
  feed : Feed,
  stages : ArrayView[ReactorStage],
  mode : ThermalMode,
  exchange : HeatExchange?,
) -> TrainResult {
  let results : Array[DesignPoint] = []
  let mut current_feed = feed
  let mut total_volume = 0.0
  let mut total_time = 0.0
  for stage in stages {
    let point = run_thermal_stage(reaction, current_feed, stage, mode, exchange)
    results.push(point)
    total_volume = total_volume + point.volume
    total_time = total_time + point.residence_time
    current_feed = {
      ..current_feed,
      concentration: point.outlet_concentration,
      temperature: point.outlet_temperature,
    }
  }
  let final_conversion = if feed.concentration <= 1.0e-12 {
    0.0
  } else {
    clamp_conversion(1.0 - current_feed.concentration / feed.concentration)
  }
  {
    stages: results,
    final_conversion,
    total_volume,
    total_residence_time: total_time,
  }
}

///|
/// Compare a train with a single reference reactor at equal total volume.
pub fn compare_train_to_single_pfr(
  reaction : Reaction,
  feed : Feed,
  stages : ArrayView[ReactorStage],
) -> (TrainResult, DesignPoint, Double) {
  let train = analyze_train(reaction, feed, stages)
  let reference = design_pfr(reaction, feed, train.total_volume)
  (train, reference, train.final_conversion - reference.conversion)
}

///|
/// Convert train results to a compact CSV table.
pub fn train_to_csv(result : TrainResult) -> String {
  let header = "stage,reactor,volume,residence_time,conversion,temperature\n"
  let body = result.stages.fold(init=header, fn(acc, point) {
    acc +
    format_double(Double::from_int(acc.length())) +
    "," +
    point.kind.to_string() +
    "," +
    format_double(point.volume) +
    "," +
    format_double(point.residence_time) +
    "," +
    format_double(point.conversion) +
    "," +
    format_double(point.outlet_temperature) +
    "\n"
  })
  body + "final_conversion," + format_double(result.final_conversion) + "\n"
}

///|
/// A stage-wise mass-balance residual for a train.
pub fn train_mass_balance_residual(feed : Feed, result : TrainResult) -> Double {
  if result.stages.length() == 0 {
    0.0
  } else {
    let first = result.stages[0]
    let last = result.stages[result.stages.length() - 1]
    let expected = feed.concentration * (1.0 - result.final_conversion)
    (last.outlet_concentration - expected).abs() +
    (first.conversion - result.stages[0].conversion).abs() * 0.0
  }
}

///|
/// Return the largest temperature excursion in a train.
pub fn train_peak_temperature(result : TrainResult) -> Double {
  result.stages.fold(init=0.0, fn(acc, point) {
    acc.max(point.outlet_temperature)
  })
}

///|
/// Return the last stage conversion gain, or zero for an empty train.
pub fn final_stage_gain(result : TrainResult) -> Double {
  if result.stages.length() < 2 {
    if result.stages.length() == 1 {
      result.stages[0].conversion
    } else {
      0.0
    }
  } else {
    let last = result.stages[result.stages.length() - 1]
    let previous = result.stages[result.stages.length() - 2]
    last.conversion - previous.conversion
  }
}

///|
fn run_thermal_stage(
  reaction : Reaction,
  feed : Feed,
  stage : ReactorStage,
  mode : ThermalMode,
  exchange : HeatExchange?,
) -> DesignPoint {
  let selected_exchange = match exchange {
    Some(hx) => Some(hx)
    None => stage.exchange
  }
  match selected_exchange {
    Some(hx) =>
      match stage.kind {
        Cstr =>
          design_cstr(
            reaction,
            feed,
            stage.volume,
            thermal_mode=mode,
            exchange=hx,
          )
        Pfr =>
          design_pfr(
            reaction,
            feed,
            stage.volume,
            thermal_mode=mode,
            exchange=hx,
          )
        Batch =>
          design_batch(
            reaction,
            feed,
            stage.volume,
            thermal_mode=mode,
            exchange=hx,
          )
      }
    None =>
      match stage.kind {
        Cstr => design_cstr(reaction, feed, stage.volume, thermal_mode=mode)
        Pfr => design_pfr(reaction, feed, stage.volume, thermal_mode=mode)
        Batch => design_batch(reaction, feed, stage.volume, thermal_mode=mode)
      }
  }
}

///|
fn run_train_stage(
  reaction : Reaction,
  feed : Feed,
  stage : ReactorStage,
) -> DesignPoint {
  run_thermal_stage(reaction, feed, stage, stage.thermal_mode, stage.exchange)
}
