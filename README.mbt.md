# moonbit-reactor

Deterministic MoonBit tools for early-stage chemical reactor design: CSTR, PFR, and batch models; kinetics; thermal screening; profiles; reactor trains; numerical solvers; sensitivity; uncertainty; validation; optimization; and offline benchmarks.

## Example

```mbt check
///|
test {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.5)
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=2.0,
    temperature=300.0,
  )
  let point = design_pfr(reaction, feed, 4.0)
  assert_true(point.conversion > 0.63 && point.conversion < 0.64)
}
```

Run the examples and benchmarks with `moon run cmd/main` and `moon run cmd/benchmarks`. The package uses Apache-2.0; model assumptions and benchmark provenance are documented in `docs/`.
