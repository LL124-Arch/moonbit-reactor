///|
pub fn residence_time(feed : Feed, volume : Double) -> Double {
  volume / feed.volumetric_flow.max(1.0e-12)
}

///|
pub fn space_time(feed : Feed, volume : Double) -> Double {
  residence_time(feed, volume)
}

///|
pub fn yield_from_conversion_selectivity(
  conversion : Double,
  selectivity : Double,
) -> Double {
  clamp_conversion(conversion) * selectivity.clamp(min=0.0, max=1.0)
}

///|
pub fn conversion_from_concentration(feed : Feed, outlet : Double) -> Double {
  if feed.concentration <= 0.0 {
    0.0
  } else {
    clamp_conversion(1.0 - outlet / feed.concentration)
  }
}
