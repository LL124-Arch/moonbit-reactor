# Design notes

## Boundary

`moonbit-reactor` is a reactor-design helper library. It intentionally does not try to become a general CFD, flowsheeting, or thermodynamics engine. The first stable boundary is:

- single-reaction CSTR, PFR, and batch models;
- ideal mixing or plug-flow assumptions;
- simple rate laws;
- lumped heat effects;
- deterministic numerical helpers suitable for early design checks.

## Model assumptions

The main design functions assume constant density and a single limiting reactant. Conversion is clamped to a physical range below one to avoid singular outlet concentrations in algebraic formulas and integrals. The heat model is a lumped engineering estimate, not a rigorous heat-transfer model.

## Numerical approach

The package uses a small bisection solver for robust scalar design equations. Bisection is slower than Newton methods, but the monotonic design equations in this package make bracketing easy to reason about. Trapezoid integration is used for PFR design equations where the rate depends on conversion through temperature.

## Extension plan

Future work should add new kinetics by extending the public `Reaction` representation or introducing a callback-based rate model. Larger changes should keep existing concrete types stable and use `moon info` to review public API changes before release.
