# Repository checklist

This checklist records reproducible repository-quality checks for `moonbit-reactor`.

## Structure

- `moon.mod` declares the public module, Apache-2.0 license, repository URL, and package metadata.
- The root package owns the public reactor types and APIs.
- `cmd/main` provides a runnable example; `cmd/benchmarks` provides an offline benchmark executable.
- Focused modules separate kinetics, design, numerics, profiles, validation, reporting, optimization, control, and safety screening.

## Validation

```bash
moon fmt --check
moon check --deny-warn --diagnostic-limit 300
moon test --deny-warn --diagnostic-limit 300
moon test --deny-warn --target native --diagnostic-limit 300
moon info
git diff --check
```

The generated `pkg.generated.mbti` files are reviewed together with public API changes.

## Benchmarks

Benchmark inputs are stored in `benchmark_data.mbt`. Each case records a category, source URL, units, assumptions, expected value, and tolerance. The benchmark executable performs no network access.

## Release hygiene

- The default branch is `main`.
- CI runs strict checks and the offline benchmark executable on Linux, macOS, and Windows.
- The working tree must be clean after formatting and interface generation.
- Release publication uses the authenticated MoonBit package workflow after local verification.
