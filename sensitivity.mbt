///|
/// Evaluate a design under a controlled perturbation.
pub fn design_with_perturbation(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  perturbation : Perturbation,
) -> DesignPoint {
  let adjusted_reaction = {
    ..reaction,
    k_ref: reaction.k_ref * perturbation.rate_multiplier.max(0.0),
  }
  let adjusted_feed = {
    ..feed,
    temperature: feed.temperature + perturbation.temperature_offset,
    volumetric_flow: feed.volumetric_flow *
    perturbation.flow_multiplier.max(0.0),
  }
  design_pfr(adjusted_reaction, adjusted_feed, volume)
}

///|
/// Calculate local sensitivities with symmetric finite differences.
pub fn design_sensitivity(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
) -> SensitivityReport {
  let dv = (volume.abs() * 1.0e-4).max(1.0e-5)
  let dk = (reaction.k_ref.abs() * 1.0e-4).max(1.0e-7)
  let dt = 1.0e-2
  let base = design_pfr(reaction, feed, volume)
  let plus_volume = design_pfr(reaction, feed, volume + dv).conversion
  let minus_volume = design_pfr(reaction, feed, (volume - dv).max(0.0)).conversion
  let plus_k = design_pfr(
      { ..reaction, k_ref: reaction.k_ref + dk },
      feed,
      volume,
    ).conversion
  let minus_k = design_pfr(
      { ..reaction, k_ref: (reaction.k_ref - dk).max(0.0) },
      feed,
      volume,
    ).conversion
  let plus_t = design_pfr(
      reaction,
      { ..feed, temperature: feed.temperature + dt },
      volume,
    ).conversion
  let minus_t = design_pfr(
      reaction,
      { ..feed, temperature: feed.temperature - dt },
      volume,
    ).conversion
  let target = base.conversion.clamp(min=1.0e-6, max=0.999998)
  let volume_for_target = required_pfr_volume(reaction, feed, target)
  {
    conversion_wrt_volume: (plus_volume - minus_volume) / (2.0 * dv),
    conversion_wrt_rate_constant: (plus_k - minus_k) / (2.0 * dk),
    conversion_wrt_temperature: (plus_t - minus_t) / (2.0 * dt),
    temperature_wrt_volume: (
      design_pfr(reaction, feed, volume + dv).outlet_temperature -
      design_pfr(reaction, feed, (volume - dv).max(0.0)).outlet_temperature
    ) /
    (2.0 * dv),
    volume_wrt_target_conversion: if base.conversion <= 1.0e-6 {
      0.0
    } else {
      (volume_for_target - volume) / target
    },
  }
}

///|
/// Compare two design points using normalized output deltas.
pub fn relative_design_change(a : DesignPoint, b : DesignPoint) -> Double {
  let conversion_scale = a.conversion.abs().max(1.0e-9)
  let temperature_scale = a.outlet_temperature.abs().max(1.0)
  (
    (b.conversion - a.conversion).abs() / conversion_scale +
    (b.outlet_temperature - a.outlet_temperature).abs() / temperature_scale
  ) /
  2.0
}

///|
/// Generate a deterministic one-factor-at-a-time response table.
pub fn sensitivity_scan(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  multipliers : ArrayView[Double],
) -> Array[DesignPoint] {
  let result : Array[DesignPoint] = []
  for multiplier in multipliers {
    result.push(
      design_pfr(
        { ..reaction, k_ref: reaction.k_ref * multiplier },
        feed,
        volume,
      ),
    )
  }
  result
}

///|
/// Build a conservative rectangular interval by evaluating all corners.
pub fn propagate_interval(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  rate_fraction : Double,
  temperature_delta : Double,
) -> ConversionInterval {
  let rates = [
    reaction.k_ref * (1.0 - rate_fraction.abs()).max(0.0),
    reaction.k_ref * (1.0 + rate_fraction.abs()),
  ]
  let temperatures = [
    feed.temperature - temperature_delta.abs(),
    feed.temperature + temperature_delta.abs(),
  ]
  let results : Array[DesignPoint] = []
  for rate in rates {
    for temperature in temperatures {
      results.push(
        design_pfr(
          { ..reaction, k_ref: rate },
          { ..feed, temperature, },
          volume,
        ),
      )
    }
  }
  let nominal = design_pfr(reaction, feed, volume)
  let minimum = results.fold(init=1.0, fn(acc, point) {
    acc.min(point.conversion)
  })
  let maximum = results.fold(init=0.0, fn(acc, point) {
    acc.max(point.conversion)
  })
  let minimum_temperature = results.fold(init=1.0e30, fn(acc, point) {
    acc.min(point.outlet_temperature)
  })
  let maximum_temperature = results.fold(init=-1.0e30, fn(acc, point) {
    acc.max(point.outlet_temperature)
  })
  {
    minimum_conversion: minimum,
    maximum_conversion: maximum,
    nominal_conversion: nominal.conversion,
    minimum_temperature,
    maximum_temperature,
  }
}

///|
/// Deterministic pseudo-random perturbation in the unit interval.
fn uncertainty_fraction(index : Int) -> Double {
  let raw = (index * 1103515245 + 12345) % 2147483647
  Double::from_int(raw.abs()) / 2147483647.0
}

///|
/// Produce deterministic samples for reproducible offline reports.
pub fn uncertainty_samples(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  samples : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  for index in 0..<samples.max(0) {
    let rate_fraction = 0.9 + 0.2 * uncertainty_fraction(index)
    let temperature = feed.temperature -
      5.0 +
      10.0 * uncertainty_fraction(index + 17)
    result.push(
      design_pfr(
        { ..reaction, k_ref: reaction.k_ref * rate_fraction },
        { ..feed, temperature, },
        volume,
      ).conversion,
    )
  }
  result
}

///|
/// Summarize deterministic uncertainty samples with nearest-rank quantiles.
pub fn uncertainty_summary(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  samples : Int,
) -> UncertaintySummary {
  let values = uncertainty_samples(reaction, feed, volume, samples)
  if values.length() == 0 {
    {
      samples: 0,
      minimum: 0.0,
      maximum: 0.0,
      mean: 0.0,
      standard_deviation: 0.0,
      p05: 0.0,
      p50: 0.0,
      p95: 0.0,
    }
  } else {
    let sorted = values
    sorted.sort()
    let mean = values.fold(init=0.0, fn(acc, value) { acc + value }) /
      Double::from_int(values.length())
    let variance = values.fold(init=0.0, fn(acc, value) {
        let delta = value - mean
        acc + delta * delta
      }) /
      Double::from_int(values.length())
    let at = fn(fraction : Double) {
      let index = (fraction * Double::from_int(sorted.length() - 1))
        .round()
        .to_int()
      sorted[index.clamp(min=0, max=sorted.length() - 1)]
    }
    {
      samples: values.length(),
      minimum: sorted[0],
      maximum: sorted[sorted.length() - 1],
      mean,
      standard_deviation: variance.sqrt(),
      p05: at(0.05),
      p50: at(0.50),
      p95: at(0.95),
    }
  }
}
