///|
pub(all) struct ReactorStage {
  kind : ReactorKind
  volume : Double
  thermal_mode : ThermalMode
  exchange : HeatExchange?
} derive(Debug, ToJson)

///|
pub(all) struct NetworkResult {
  stages : Array[DesignPoint]
  final_conversion : Double
  final_concentration : Double
  final_temperature : Double
  total_volume : Double
} derive(Debug, ToJson)

///|
pub fn ReactorStage::cstr(
  volume~ : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> ReactorStage {
  { kind: Cstr, volume, thermal_mode, exchange }
}

///|
pub fn ReactorStage::pfr(
  volume~ : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> ReactorStage {
  { kind: Pfr, volume, thermal_mode, exchange }
}

///|
pub fn ReactorStage::batch(
  time~ : Double,
  thermal_mode? : ThermalMode = Isothermal,
  exchange? : HeatExchange,
) -> ReactorStage {
  { kind: Batch, volume: time, thermal_mode, exchange }
}

///|
pub fn run_network(
  reaction : Reaction,
  feed : Feed,
  stages : ArrayView[ReactorStage],
) -> NetworkResult {
  let results : Array[DesignPoint] = []
  let final_feed = for i = 0, current = feed, total_x = 0.0
                       i < stages.length()
                       i = i + 1 {
    let stage = stages[i]
    let point = run_stage(reaction, current, stage)
    results.push({
      ..point,
      conversion: combine_conversion(total_x, point.conversion),
    })
    continue i + 1,
      {
        concentration: point.outlet_concentration,
        volumetric_flow: current.volumetric_flow,
        temperature: point.outlet_temperature,
        heat_capacity_flow: current.heat_capacity_flow,
      },
      combine_conversion(total_x, point.conversion)
  } nobreak {
    current
  }
  let total_volume = for i = 0, acc = 0.0; i < stages.length(); i = i + 1 {
    continue i + 1, acc + stages[i].volume
  } nobreak {
    acc
  }
  {
    stages: results,
    final_conversion: if feed.concentration <= 0.0 {
      0.0
    } else {
      clamp_conversion(1.0 - final_feed.concentration / feed.concentration)
    },
    final_concentration: final_feed.concentration,
    final_temperature: final_feed.temperature,
    total_volume,
  }
}

///|
fn run_stage(
  reaction : Reaction,
  feed : Feed,
  stage : ReactorStage,
) -> DesignPoint {
  match stage.kind {
    Cstr =>
      match stage.exchange {
        Some(hx) =>
          design_cstr(
            reaction,
            feed,
            stage.volume,
            thermal_mode=stage.thermal_mode,
            exchange=hx,
          )
        None =>
          design_cstr(
            reaction,
            feed,
            stage.volume,
            thermal_mode=stage.thermal_mode,
          )
      }
    Pfr =>
      match stage.exchange {
        Some(hx) =>
          design_pfr(
            reaction,
            feed,
            stage.volume,
            thermal_mode=stage.thermal_mode,
            exchange=hx,
          )
        None =>
          design_pfr(
            reaction,
            feed,
            stage.volume,
            thermal_mode=stage.thermal_mode,
          )
      }
    Batch =>
      match stage.exchange {
        Some(hx) =>
          design_batch(
            reaction,
            feed,
            stage.volume,
            thermal_mode=stage.thermal_mode,
            exchange=hx,
          )
        None =>
          design_batch(
            reaction,
            feed,
            stage.volume,
            thermal_mode=stage.thermal_mode,
          )
      }
  }
}

///|
fn combine_conversion(previous : Double, stage_conversion : Double) -> Double {
  clamp_conversion(1.0 - (1.0 - previous) * (1.0 - stage_conversion))
}

///|
pub fn equal_volume_cstr_train(
  stages : Int,
  total_volume : Double,
  thermal_mode? : ThermalMode = Isothermal,
) -> Array[ReactorStage] {
  let n = stages.max(1)
  let volume = total_volume / Double::from_int(n)
  let out : Array[ReactorStage] = []
  for _ in 0..<n {
    out.push(ReactorStage::cstr(volume~, thermal_mode~))
  }
  out
}

///|
pub fn equal_volume_pfr_train(
  stages : Int,
  total_volume : Double,
  thermal_mode? : ThermalMode = Isothermal,
) -> Array[ReactorStage] {
  let n = stages.max(1)
  let volume = total_volume / Double::from_int(n)
  let out : Array[ReactorStage] = []
  for _ in 0..<n {
    out.push(ReactorStage::pfr(volume~, thermal_mode~))
  }
  out
}
