# moonbit-reactor

`moonbit-reactor` is a deterministic MoonBit toolkit for early-stage chemical reactor design. It provides typed CSTR, PFR, and batch models, reaction kinetics, thermal screening, reactor-train analysis, numerical solvers, sensitivity studies, uncertainty intervals, engineering metrics, and offline benchmark reports.

## Core capabilities

- Isothermal, adiabatic, and lumped jacketed CSTR/PFR/batch calculations.
- Zero-, first-, and second-order kinetics, Arrhenius correction, reversible, series, and parallel helpers.
- Bisection diagnostics, trapezoid/Simpson/adaptive quadrature, Euler and RK4 integration.
- Axial and batch profiles, reactor-train analysis, conversion/selectivity/productivity metrics.
- Deterministic sensitivity scans, interval propagation, uncertainty summaries, and bounded control helpers.
- Design envelopes, grid-search optimization, cost screening, validation reports, Markdown and CSV output.
- Offline benchmark cases with source URLs, units, assumptions, expected values, and tolerances.

## Quick start

```bash
moon run cmd/main
moon run cmd/benchmarks
```

Library example:

```mbt check
///|
test {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.5)
  let feed = Feed::new(concentration=1.0, volumetric_flow=2.0, temperature=300.0)
  let point = design_pfr(reaction, feed, 4.0)
  assert_true(point.conversion > 0.63 && point.conversion < 0.64)
}
```

## CLI

- `moon run cmd/main` runs a compact engineering example.
- `moon run cmd/benchmarks` executes all offline regression cases and prints Markdown and CSV-ready results.

## Architecture

The root package owns the public data types and design APIs. Focused modules separate kinetics, numerical methods, profiles, networks, validation, reporting, optimization, thermal properties, sensitivity, control, and safety screening. `cmd/main` and `cmd/benchmarks` consume the same public APIs as downstream packages.

See [docs/DESIGN.md](docs/DESIGN.md) for assumptions and [docs/benchmarks.md](docs/benchmarks.md) for provenance.

## Benchmarks

The benchmark suite is offline and reproducible. Analytical cases use closed-form reactor identities; source-backed records preserve their units and assumptions; screening cases are explicitly labeled as engineering scenarios. Run:

```bash
moon run cmd/benchmarks
```

## Testing and CI

```bash
moon fmt --check
moon check --deny-warn --diagnostic-limit 300
moon test --deny-warn --diagnostic-limit 300
moon test --deny-warn --target native --diagnostic-limit 300
moon info
git diff --check
```

GitHub Actions runs formatting, strict checks, interface generation, tests on native and default targets, and the offline benchmark command across Linux, macOS, and Windows.

## Scope

This package targets deterministic engineering education and early process screening. It does not claim CFD, multiphase simulation, thermodynamic property prediction, unit algebra, plant safety certification, or arbitrary reaction-graph solving.

## License

Apache-2.0. See [LICENSE](LICENSE).
