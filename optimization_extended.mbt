///|
/// A bounded one-dimensional search configuration.
pub(all) struct SearchConfig {
  minimum : Double
  maximum : Double
  steps : Int
} derive(Debug, ToJson)

///|
/// Construct a normalized search configuration.
pub fn SearchConfig::new(
  minimum~ : Double,
  maximum~ : Double,
  steps~ : Int,
) -> SearchConfig {
  {
    minimum: minimum.min(maximum),
    maximum: maximum.max(minimum),
    steps: steps.max(1),
  }
}

///|
/// Sample a closed interval uniformly.
pub fn uniform_grid(config : SearchConfig) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<=config.steps {
    let fraction = Double::from_int(i) / Double::from_int(config.steps)
    result.push(config.minimum + fraction * (config.maximum - config.minimum))
  }
  result
}

///|
/// Evaluate a scalar objective over a uniform grid.
pub fn evaluate_grid(
  config : SearchConfig,
  objective : (Double) -> Double,
) -> Array[ObjectiveScore] {
  let result : Array[ObjectiveScore] = []
  for x in uniform_grid(config) {
    let score = objective(x)
    result.push({
      volume: x,
      conversion: 0.0,
      temperature: 0.0,
      score,
      feasible: true,
    })
  }
  result
}

///|
/// Return the minimizer of a scalar objective.
pub fn minimum_scalar(scores : ArrayView[ObjectiveScore]) -> ObjectiveScore? {
  let mut best : ObjectiveScore? = None
  for score in scores {
    match best {
      None => best = Some(score)
      Some(current) => if score.score < current.score { best = Some(score) }
    }
  }
  best
}

///|
/// Return the maximizer of a scalar objective.
pub fn maximum_scalar(scores : ArrayView[ObjectiveScore]) -> ObjectiveScore? {
  best_objective(scores)
}

///|
/// Penalize an infeasible objective without changing feasible ranking.
pub fn penalty_score(
  score : Double,
  feasible : Bool,
  penalty : Double,
) -> Double {
  if feasible {
    score
  } else {
    score - penalty.abs()
  }
}

///|
/// Pareto dominance for conversion, volume, and temperature.
pub fn dominates(a : ObjectiveScore, b : ObjectiveScore) -> Bool {
  let no_worse = a.conversion >= b.conversion &&
    a.volume <= b.volume &&
    a.temperature <= b.temperature
  let strictly_better = a.conversion > b.conversion ||
    a.volume < b.volume ||
    a.temperature < b.temperature
  no_worse && strictly_better
}

///|
/// Filter a set to its non-dominated frontier.
pub fn pareto_frontier(
  scores : ArrayView[ObjectiveScore],
) -> Array[ObjectiveScore] {
  let frontier : Array[ObjectiveScore] = []
  for candidate in scores {
    let mut dominated = false
    for other in scores {
      if dominates(other, candidate) {
        dominated = true
      }
    }
    if !dominated {
      frontier.push(candidate)
    }
  }
  frontier
}

///|
/// Compute a weighted distance from a target design.
pub fn target_distance(
  point : ObjectiveScore,
  target_conversion : Double,
  target_volume : Double,
  target_temperature : Double,
) -> Double {
  (point.conversion - target_conversion).abs() +
  (point.volume - target_volume).abs() +
  (point.temperature - target_temperature).abs()
}

///|
/// Select the closest target design.
pub fn closest_target(
  scores : ArrayView[ObjectiveScore],
  target_conversion : Double,
  target_volume : Double,
  target_temperature : Double,
) -> ObjectiveScore? {
  let mut best : ObjectiveScore? = None
  let mut best_distance = 1.0e30
  for score in scores {
    let distance = target_distance(
      score, target_conversion, target_volume, target_temperature,
    )
    if distance < best_distance {
      best = Some(score)
      best_distance = distance
    }
  }
  best
}

///|
/// Find the smallest volume satisfying a conversion target and temperature limit.
pub fn optimize_pfr_volume(
  reaction : Reaction,
  feed : Feed,
  config : SearchConfig,
  target_conversion : Double,
  maximum_temperature : Double,
) -> ObjectiveScore? {
  let points : Array[ObjectiveScore] = []
  for volume in uniform_grid(config) {
    let point = design_pfr(reaction, feed, volume)
    if point.conversion >= clamp_conversion(target_conversion) &&
      point.outlet_temperature <= maximum_temperature {
      points.push(score_design(point, 1.0, 0.0, maximum_temperature))
    }
  }
  if points.length() == 0 {
    None
  } else {
    let mut best = points[0]
    for point in points {
      if point.volume < best.volume {
        best = point
      }
    }
    Some(best)
  }
}

///|
/// Optimize a CSTR/PFR train count at fixed total volume.
pub fn optimize_train_count(
  reaction : Reaction,
  feed : Feed,
  total_volume : Double,
  minimum_stages : Int,
  maximum_stages : Int,
) -> ObjectiveScore? {
  let mut best : ObjectiveScore? = None
  for
    count in minimum_stages.min(maximum_stages)..<=maximum_stages.max(
      minimum_stages,
    ) {
    let stages = equal_volume_cstr_train(count, total_volume)
    let result = run_network(reaction, feed, stages)
    let point = {
      volume: total_volume,
      conversion: result.final_conversion,
      temperature: result.final_temperature,
      score: result.final_conversion,
      feasible: true,
    }
    match best {
      None => best = Some(point)
      Some(current) =>
        if point.conversion > current.conversion {
          best = Some(point)
        }
    }
  }
  best
}

///|
/// Search a reaction rate multiplier under a thermal limit.
pub fn optimize_rate_multiplier(
  reaction : Reaction,
  feed : Feed,
  volume : Double,
  config : SearchConfig,
  maximum_temperature : Double,
) -> ObjectiveScore? {
  let scores : Array[ObjectiveScore] = []
  for multiplier in uniform_grid(config) {
    let point = design_pfr(
      { ..reaction, k_ref: reaction.k_ref * multiplier.max(0.0) },
      feed,
      volume,
    )
    if point.outlet_temperature <= maximum_temperature {
      scores.push(score_design(point, 1.0, 0.0, maximum_temperature))
    }
  }
  best_objective(scores)
}

///|
/// Return the percentage improvement between two objective scores.
pub fn objective_improvement(
  reference : ObjectiveScore,
  candidate : ObjectiveScore,
) -> Double {
  if reference.score.abs() <= 1.0e-12 {
    0.0
  } else {
    (candidate.score - reference.score) / reference.score.abs()
  }
}

///|
/// Stable tie-breaking comparator for design scores.
pub fn score_precedes(a : ObjectiveScore, b : ObjectiveScore) -> Bool {
  if a.score != b.score {
    a.score > b.score
  } else {
    a.volume < b.volume
  }
}

///|
/// Select the first score under a maximum volume.
pub fn first_under_volume(
  scores : ArrayView[ObjectiveScore],
  maximum_volume : Double,
) -> ObjectiveScore? {
  for score in scores {
    if score.volume <= maximum_volume {
      return Some(score)
    }
  }
  None
}

///|
/// Select the last score over a minimum conversion.
pub fn last_over_conversion(
  scores : ArrayView[ObjectiveScore],
  minimum_conversion : Double,
) -> ObjectiveScore? {
  let mut result : ObjectiveScore? = None
  for score in scores {
    if score.conversion >= minimum_conversion {
      result = Some(score)
    }
  }
  result
}
