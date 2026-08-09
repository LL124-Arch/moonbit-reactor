# Reactor Engineering Expansion Design

**Status:** Approved for implementation

**Goal:** Extend `moonbit-reactor` from a compact reactor-equation library into a reusable engineering screening package with richer reaction networks, source-traceable benchmark cases, solver diagnostics, and broad boundary coverage.

## Scope

The release target is `v0.2`. Existing public constructors and design functions remain source-compatible. New APIs are additive and are organized around four responsibilities:

1. **Engineering metrics:** expose residence time, space time, reactant conversion, selectivity, and yield without requiring consumers to recompute them from a `DesignPoint`.
2. **Kinetics and reaction networks:** add explicit reversible first-order behavior and a small set of typed series/parallel reaction helpers. The implementation remains deterministic and intentionally excludes CFD, thermodynamic property packages, multiphase flow, and arbitrary callback-driven reaction graphs.
3. **Numerical diagnostics:** make root and integration limits observable. A failed bracket or invalid numerical range must produce a result that says why it failed instead of silently returning a plausible-looking number.
4. **Evidence and verification:** register public benchmark cases with source metadata, units, assumptions, expected values, and tolerances; add boundary tests for physical limits, invalid inputs, extreme temperature sensitivity, and network behavior.

## Proposed architecture

The root package remains the public facade and continues to own the public domain types. The implementation is split into focused files:

- `metrics.mbt`: derived process metrics and selectivity/yield calculations.
- `kinetics_extended.mbt`: reversible, series, and parallel rate helpers that reuse the existing `Reaction` data model where possible.
- `solver_diagnostics.mbt`: solver status, failure reason, and configurable numerical settings.
- `benchmarks.mbt`: source-traceable benchmark records and curated public cases.
- `benchmark_data.mbt`: numeric records only, separated from calculation code so data review is easy.
- `boundary_cases.mbt`: named extreme and invalid inputs used by tests and the CLI.
- Existing `design.mbt`, `kinetics.mbt`, `numerics.mbt`, and `validation.mbt`: targeted compatibility changes only where the new diagnostics and metrics need to be threaded through.

The command package gains subcommand-like flags through a small argument parser only if that can be done without introducing a dependency. The default command continues to print the existing demo report; a `--benchmarks` mode prints benchmark outcomes and a `--csv` mode prints machine-readable sweep output.

## Benchmark evidence

Benchmarks will distinguish three categories:

- **Analytical reference:** first-order PFR/CSTR relations from open chemical-reaction-engineering teaching material. Expected values are calculated from the cited equation and checked at a fixed tolerance.
- **Measured-property reference:** molecular properties and thermochemical values from NIST Chemistry WebBook or an equivalent primary/official database. These values are stored with source URL, CAS/species, units, and retrieval date.
- **Literature kinetics reference:** reaction-rate parameters from a publicly accessible paper, university laboratory manual, or NIST Chemical Kinetics Database. The code will label these as literature parameters and will not imply plant-scale validation.

The first benchmark set will include:

- first-order PFR versus CSTR conversion at several Damkohler numbers;
- ethyl acetate saponification as a second-order aqueous reaction with explicit concentration and rate-constant provenance;
- a first-order series reaction with intermediate selectivity and yield checks;
- an exothermic CSTR temperature-boundary case with a declared lumped heat-capacity assumption;
- a batch integration case whose closed-form first-order conversion provides a regression oracle.

## Numerical behavior

Existing formulas preserve their current behavior for valid inputs. New validation and diagnostic APIs will cover:

- zero and negative concentration, flow, volume, time, heat-capacity flow, and heat-transfer coefficients;
- conversion targets at `0`, near `1`, exactly `1`, and outside the physical interval;
- empty or reversed integration ranges;
- insufficient or invalid root brackets;
- Arrhenius temperatures at and below zero Kelvin;
- stiffness-like temperature sensitivity and non-monotonic thermal scans.

The default numerical settings will be conservative and deterministic. A calculation that cannot be bracketed or converged returns an explicit status record. Existing convenience functions may continue to return a best-effort `DesignPoint`, but the new diagnostic entry points are the recommended API for production screening and are used by the CLI benchmark report.

## Test plan

Implementation follows test-first cycles. Each public behavior gets a black-box test, while white-box tests are reserved for private numerical helpers. The test suite will be expanded from the current 18 tests to at least 40 focused tests, including:

- analytical values and monotonicity for each reactor kind;
- reversible and series/parallel reaction behavior;
- metric identities such as yield = conversion * selectivity where applicable;
- benchmark provenance and tolerance checks;
- solver failure statuses and recovery from valid brackets;
- physical clipping and invalid-input reports;
- extreme temperatures, near-complete conversion, empty sweeps, and zero-stage networks;
- stable Markdown and CSV output.

CI will run formatting, strict checking, generated-interface verification, normal tests, native-target tests, and the benchmark command. Documentation will show the exact commands and clearly separate model assumptions from measured data.

## Acceptance criteria

- `moon fmt --check`, `moon check --deny-warn`, `moon test --deny-warn`, and `moon info` pass locally and in CI.
- All benchmark records have a public source, units, assumptions, expected values, and tolerance.
- No existing public API is removed or renamed.
- The CLI can run the benchmark suite without network access.
- GitHub and GitLink contain the same source tree and release documentation, with commits authored only by the respective repository account owner.
