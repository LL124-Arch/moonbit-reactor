# moonbit-reactor

`moonbit-reactor` is a MoonBit library for chemical reactor design calculations. It focuses on common engineering models rather than full fluid simulation: CSTR, PFR, and batch reactors; zero-, first-, and second-order kinetics; isothermal, adiabatic, and jacketed non-isothermal estimates; small root finding and integration helpers; and reusable examples for teaching or early process screening.

The project is prepared for the MoonBit OSC2026 open-source ecosystem competition. The scope is deliberately larger than a single formula collection, but still small enough to be tested and maintained as a practical MoonBit package.

## Why this project

MoonBit already has useful foundations for general programming, but domain libraries for engineering calculation are still scarce. Chemical reactor design is a good fit for a reusable ecosystem package because the core APIs are typed, deterministic, testable, and easy to run across MoonBit targets.

Before selecting this topic, I checked mooncakes.io with reactor-related keywords such as `reactor`, `CSTR`, `PFR`, `batch`, and `chemical`. I did not find a mature MoonBit package that overlaps heavily with this exact CSTR/PFR/Batch reactor-design scope.

## Features

- CSTR, PFR, and batch reactor design points.
- Zero-, first-, and second-order rate laws.
- Arrhenius temperature correction.
- Isothermal, adiabatic, and cooled non-isothermal calculation modes.
- Required volume solvers for target conversion.
- Bisection root finder and trapezoid/Euler numerical helpers.
- Reactor sweep utilities for plotting conversion or temperature profiles.
- Input validation reports for invalid or suspicious design parameters.
- Reactor-stage networks for CSTR/PFR train comparison.
- Markdown and CSV-style reporting helpers.
- Grid-search utilities for constrained early design choices.
- Example cases: ethyl acetate saponification, first-order series reaction, and exothermic CSTR safety boundary.

## Quick start

Run the example CLI:

```bash
moon run cmd/main
```

Use the library from MoonBit code:

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
  assert_true(point.conversion > 0.63)
  assert_true(point.conversion < 0.64)
}
```

Estimate a cooled, non-isothermal CSTR:

```mbt check
///|
test {
  let reaction = Reaction::new(
    name="cooled exothermic reaction",
    order=First,
    k_ref=0.05,
    reaction_enthalpy=-80000.0,
  )
  let feed = Feed::new(
    concentration=1.0,
    volumetric_flow=1.0,
    temperature=330.0,
    heat_capacity_flow=6000.0,
  )
  let hx = HeatExchange::new(ua=3000.0, coolant_temperature=300.0)
  let point = design_cstr(
    reaction,
    feed,
    15.0,
    thermal_mode=NonIsothermal,
    exchange=hx,
  )
  assert_true(point.outlet_temperature < 330.0)
}
```

## API overview

- `Reaction`: kinetic order, reference rate constant, Arrhenius parameters, and reaction enthalpy.
- `Feed`: inlet concentration, flow rate, inlet temperature, and heat-capacity flow.
- `HeatExchange`: lumped `UA` and coolant temperature for early cooled-reactor estimates.
- `DesignPoint`: reactor kind, volume, residence time, conversion, outlet concentration, outlet temperature, heat removal, and outlet rate.
- `SafetyBoundary`: maximum safe volume or residence time under a temperature constraint.

Main functions:

- `design_cstr`
- `design_pfr`
- `design_batch`
- `required_cstr_volume`
- `required_pfr_volume`
- `sweep_cstr`
- `sweep_pfr`
- `find_temperature_boundary`
- `run_network`
- `equal_volume_cstr_train`
- `sweep_to_csv`
- `maximize_conversion_under_temperature`
- `minimize_volume_for_conversion`

## Validation

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon test --deny-warn --target native
moon info
git diff --exit-code
```

Current MoonBit builds expose `--deny-warn` for check/test. `moon fmt` uses `--check`, and `moon info` is verified by checking that generated `pkg.generated.mbti` files are committed and unchanged.

## Competition notes

- License: Apache-2.0.
- Repository type: public MoonBit library with CLI example.
- Contributors: only the repository account owner should appear in commits.
- AI usage: AI assisted implementation and documentation polishing; the project design, scope, validation, and open-source compliance remain manually reviewed.
- Mooncakes plan: publish after repository URLs, CI, and interface files are stable.

## Roadmap

- Add more irreversible and reversible rate law helpers.
- Add dimension-aware wrappers once the MoonBit ecosystem has a stable units package.
- Add CSV-style sweep export for plotting tools.
- Add more examples from reaction-engineering textbooks and open course material.
- Keep public API changes visible through `moon info` generated interfaces.
