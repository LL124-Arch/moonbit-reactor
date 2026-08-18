///|
/// A deterministic linearly spaced sample.
pub fn linspace(
  minimum : Double,
  maximum : Double,
  count : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let n = count.max(0)
  if n == 0 {
    result
  } else if n == 1 {
    result.push(minimum)
    result
  } else {
    for i in 0..<n {
      result.push(
        minimum +
        (maximum - minimum) * Double::from_int(i) / Double::from_int(n - 1),
      )
    }
    result
  }
}

///|
/// Generate geometric samples over positive bounds.
pub fn logspace(
  minimum : Double,
  maximum : Double,
  count : Int,
) -> Array[Double] {
  let low = natural_log(minimum.max(1.0e-12))
  let high = natural_log(maximum.max(1.0e-12))
  linspace(low, high, count).map(fn(x) { @math.exp(x) })
}

///|
/// Midpoints of an ordered sample grid.
pub fn midpoints(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() >= 2 {
    for i in 0..<(values.length() - 1) {
      result.push((values[i] + values[i + 1]) / 2.0)
    }
  }
  result
}

///|
/// Difference between adjacent samples.
pub fn adjacent_differences(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() >= 2 {
    for i in 0..<(values.length() - 1) {
      result.push(values[i + 1] - values[i])
    }
  }
  result
}

///|
/// Trapezoid area for tabulated data.
pub fn tabulated_trapezoid(
  x : ArrayView[Double],
  y : ArrayView[Double],
) -> Double {
  let count = x.length().min(y.length())
  if count < 2 {
    0.0
  } else {
    for i = 1, area = 0.0; i < count; i = i + 1 {
      continue i + 1, area + (x[i] - x[i - 1]) * (y[i] + y[i - 1]) / 2.0
    } nobreak {
      area
    }
  }
}

///|
/// Weighted mean of a tabulated signal.
pub fn weighted_mean(
  values : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double {
  let count = values.length().min(weights.length())
  let total_weight = for i = 0, total = 0.0; i < count; i = i + 1 {
    continue i + 1, total + weights[i]
  } nobreak {
    total
  }
  if total_weight.abs() <= 1.0e-12 {
    0.0
  } else {
    let weighted = for i = 0, total = 0.0; i < count; i = i + 1 {
      continue i + 1, total + values[i] * weights[i]
    } nobreak {
      total
    }
    weighted / total_weight
  }
}

///|
/// Root-mean-square of a signal.
pub fn root_mean_square(values : ArrayView[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let total = values.fold(init=0.0, fn(acc, value) { acc + value * value })
    (total / Double::from_int(values.length())).sqrt()
  }
}

///|
/// Mean absolute error between two equal-length signals.
pub fn mean_absolute_error(
  first : ArrayView[Double],
  second : ArrayView[Double],
) -> Double {
  let count = first.length().min(second.length())
  if count == 0 {
    0.0
  } else {
    let total = for i = 0, acc = 0.0; i < count; i = i + 1 {
      continue i + 1, acc + (first[i] - second[i]).abs()
    } nobreak {
      acc
    }
    total / Double::from_int(count)
  }
}

///|
/// Maximum absolute error between two signals.
pub fn maximum_absolute_error(
  first : ArrayView[Double],
  second : ArrayView[Double],
) -> Double {
  let count = first.length().min(second.length())
  for i = 0, error = 0.0; i < count; i = i + 1 {
    continue i + 1, error.max((first[i] - second[i]).abs())
  } nobreak {
    error
  }
}

///|
/// Normalize a signal to a target range.
pub fn normalize_to_range(
  values : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let low = values.fold(init=1.0e30, fn(acc, x) { acc.min(x) })
  let high = values.fold(init=-1.0e30, fn(acc, x) { acc.max(x) })
  let span = (high - low).max(1.0e-12)
  values.map(fn(x) { minimum + (x - low) / span * (maximum - minimum) })
}

///|
/// Clip a sampled signal to a physical range.
pub fn clip_values(
  values : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  values.map(fn(x) {
    x.clamp(min=minimum.min(maximum), max=maximum.max(minimum))
  })
}

///|
/// First-order low-pass filter for deterministic sampled data.
pub fn low_pass(values : ArrayView[Double], alpha : Double) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() == 0 {
    result
  } else {
    let weight = alpha.clamp(min=0.0, max=1.0)
    let mut state = values[0]
    result.push(state)
    for value in values[1:] {
      state = state + weight * (value - state)
      result.push(state)
    }
    result
  }
}

///|
/// Compute a discrete first difference.
pub fn first_difference(
  values : ArrayView[Double],
  step : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  if values.length() >= 2 {
    for i in 0..<(values.length() - 1) {
      result.push((values[i + 1] - values[i]) / step.max(1.0e-12))
    }
  }
  result
}

///|
/// Detect a sign change between adjacent samples.
pub fn sign_change_count(values : ArrayView[Double]) -> Int {
  if values.length() < 2 {
    0
  } else {
    for i = 1, count = 0; i < values.length(); i = i + 1 {
      let changed = (values[i - 1] < 0.0 && values[i] >= 0.0) ||
        (values[i - 1] >= 0.0 && values[i] < 0.0)
      continue i + 1, if changed { count + 1 } else { count }
    } nobreak {
      count
    }
  }
}

///|
/// Return the index of the largest sampled value.
pub fn argmax(values : ArrayView[Double]) -> Int? {
  if values.length() == 0 {
    None
  } else {
    let mut index = 0
    for i in 1..<values.length() {
      if values[i] > values[index] {
        index = i
      }
    }
    Some(index)
  }
}

///|
/// Return the index of the smallest sampled value.
pub fn argmin(values : ArrayView[Double]) -> Int? {
  if values.length() == 0 {
    None
  } else {
    let mut index = 0
    for i in 1..<values.length() {
      if values[i] < values[index] {
        index = i
      }
    }
    Some(index)
  }
}
