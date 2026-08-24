# Design notes

## Boundary

`moonbit-reactor` is a reactor-design helper library. It intentionally does not try to become a general CFD, flowsheeting, or thermodynamics engine. The first stable boundary is:

- single-reaction CSTR, PFR, and batch models;
- ideal mixing or plug-flow assumptions;
- simple rate laws;
- lumped heat effects;
- deterministic numerical helpers suitable for early design checks.
- source-traceable benchmark records that run offline in CI.

## Model assumptions

The main design functions assume constant density and a single limiting reactant. Conversion is clamped to a physical range below one to avoid singular outlet concentrations in algebraic formulas and integrals. The heat model is a lumped engineering estimate, not a rigorous heat-transfer model.

## Numerical approach

The package uses a small bisection solver for robust scalar design equations. Bisection is slower than Newton methods, but the monotonic design equations in this package make bracketing easy to reason about. Trapezoid integration is used for PFR design equations where the rate depends on conversion through temperature.

The public `SolverReport` API records whether a calculation converged, failed to
find a bracket, exhausted its iteration budget, or received an invalid range.
The original value-returning helpers remain available for compact scripts.

## Engineering workflow helpers

The validation module reports suspicious or invalid inputs without forcing a single application-level error policy. The network module lets users compare reactor trains, such as several equal-volume CSTRs against one large CSTR. The reporting module keeps CLI and notebook-like workflows simple by producing Markdown tables and CSV sweep output from the same typed design objects. The optimizer module is intentionally a grid search: it is predictable, easy to test, and sufficient for early feasibility scans.

The benchmark module keeps source metadata alongside expected values. Analytical
benchmarks test equations, literature benchmarks test a reported parameter in a
declared model, measured-property benchmarks test a transcribed database value,
and screening benchmarks document project assumptions without claiming external
validation.

## Extension policy

Future extensions should preserve the current model boundary and keep existing
concrete types stable. New public APIs must be reviewed with `moon info`,
accompanied by black-box tests, and added to the benchmark or documentation
surface when they affect engineering outputs.
