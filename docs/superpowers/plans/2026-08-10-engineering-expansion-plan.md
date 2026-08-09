# Reactor Engineering Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task with review checkpoints.

**Goal:** Deliver `v0.2` of `moonbit-reactor` with expanded engineering metrics, typed reaction-pattern helpers, explicit numerical diagnostics, source-traceable benchmarks, broad boundary tests, and updated CLI/CI documentation.

**Architecture:** Keep the root package as the public API owner. Add focused files for metrics, extended kinetics, solver diagnostics, benchmark records, and boundary cases. Preserve all existing public constructors and design functions; new APIs are additive and the CLI consumes the same public benchmark/reporting functions as library users.

**Tech Stack:** MoonBit 0.10.x, `moon` formatter/check/test/info, existing `moonbitlang/core/math`, GitHub Actions, GitLink workflow metadata, Markdown/CSV reports.

---

### Task 1: Add engineering metrics and boundary-focused tests

**Files:**
- Create: `metrics.mbt`
- Create: `boundary_cases.mbt`
- Modify: `moonbit-reactor_test.mbt`

- [ ] **Step 1: Write failing black-box tests**

Add tests for residence/space-time identity, yield calculation, a series-reaction selectivity limit, zero-volume behavior, near-complete conversion clamping, and an empty sweep. The test expressions should use only public functions, for example:

```mbt
test "engineering metrics preserve design point identities" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(concentration=1.0, volumetric_flow=2.0, temperature=300.0)
  let point = design_pfr(reaction, feed, 4.0)
  assert_true(nearly_equal(space_time(feed, point.volume), 2.0))
  assert_true(nearly_equal(point.residence_time, residence_time(feed, point.volume)))
  assert_true(nearly_equal(yield_from_conversion_selectivity(point.conversion, 1.0), point.conversion))
}

test "boundary cases remain physical" {
  let reaction = Reaction::new(name="A -> B", order=First, k_ref=0.2)
  let feed = Feed::new(concentration=1.0, volumetric_flow=1.0, temperature=300.0)
  assert_eq(design_pfr(reaction, feed, 0.0).conversion, 0.0)
  assert_true(design_pfr(reaction, feed, 1.0e9).conversion < 1.0)
  assert_eq(sweep_pfr(reaction, feed, 5.0, 0).length(), 0)
}
```

- [ ] **Step 2: Run the focused tests and verify the expected RED state**

Run `moon test moonbit-reactor_test.mbt --deny-warn`. Expected failure: the metric functions and the explicit empty-sweep behavior do not exist yet.

- [ ] **Step 3: Implement the minimal metrics API**

Create `metrics.mbt` with these public functions:

```mbt
///|
pub fn residence_time(feed : Feed, volume : Double) -> Double {
  volume / feed.volumetric_flow.max(1.0e-12)
}

///|
pub fn space_time(feed : Feed, volume : Double) -> Double {
  residence_time(feed, volume)
}

///|
pub fn yield_from_conversion_selectivity(
  conversion : Double,
  selectivity : Double,
) -> Double {
  clamp_conversion(conversion) * selectivity.clamp(min=0.0, max=1.0)
}

///|
pub fn conversion_from_concentration(feed : Feed, outlet : Double) -> Double {
  if feed.concentration <= 0.0 {
    0.0
  } else {
    clamp_conversion(1.0 - outlet / feed.concentration)
  }
}
```

Update `make_design_point` to reuse `residence_time`. Update sweep construction so `count <= 0` returns an empty array and `count == 1` returns exactly the upper endpoint. Keep the existing `count >= 2` behavior unchanged.

- [ ] **Step 4: Run the focused tests and then the full existing suite**

Run `moon fmt`, `moon check --deny-warn`, and `moon test --deny-warn`. Expected result: all prior tests plus the new metrics/boundary tests pass.

- [ ] **Step 5: Commit**

```powershell
git add metrics.mbt boundary_cases.mbt moonbit-reactor_test.mbt design.mbt sweep.mbt
git commit -m "feat: add reactor engineering metrics and boundaries"
```

### Task 2: Add explicit numerical solver diagnostics

**Files:**
- Create: `solver_diagnostics.mbt`
- Modify: `types.mbt`
- Modify: `numerics.mbt`
- Modify: `moonbit-reactor_test.mbt`

- [ ] **Step 1: Write failing tests for invalid brackets and ranges**

Add black-box tests asserting that an invalid bisection bracket reports `BracketFailure`, a valid root reports `Converged`, and a reversed trapezoid interval reports a deterministic negative integral rather than a NaN. Add a settings test for a small iteration budget.

- [ ] **Step 2: Run the focused tests and verify RED**

Run `moon test moonbit-reactor_test.mbt --deny-warn`. Expected failure: the new status enum and diagnostic entry point are absent.

- [ ] **Step 3: Add public diagnostic types and a compatibility wrapper**

Add to `types.mbt`:

```mbt
pub(all) enum SolverStatus {
  Converged
  BracketFailure
  IterationLimit
  InvalidRange
} derive(Debug, Eq, ToJson)

pub(all) struct SolverReport {
  status : SolverStatus
  root : Double
  residual : Double
  iterations : Int
} derive(Debug, ToJson)
```

Create `solver_diagnostics.mbt` with `bisect_report(lower, upper, f, settings?) -> SolverReport`. It must check non-finite endpoints, evaluate both endpoint residuals, return `BracketFailure` when the signs do not bracket a root, return `Converged` for endpoint or tolerance success, and return `IterationLimit` after the configured loop. Keep existing `bisect` as a wrapper that maps `SolverReport` to the existing `BracketResult`, preserving its public signature.

- [ ] **Step 4: Add guarded integration entry point**

Add `integrate_trapezoid_report(lower, upper, steps, f) -> SolverReport` where `root` stores the integral, `residual` is `0.0`, and `status` is `InvalidRange` when `steps <= 0` or an endpoint is non-finite; otherwise use the existing trapezoid calculation and `Converged`. Keep `integrate_trapezoid` as the existing value-returning wrapper.

- [ ] **Step 5: Run all numerical tests and inspect generated API**

Run `moon fmt`, `moon check --deny-warn`, `moon test --deny-warn`, and `moon info`. Review `pkg.generated.mbti` to ensure only the intended additive API appears.

- [ ] **Step 6: Commit**

```powershell
git add types.mbt solver_diagnostics.mbt numerics.mbt moonbit-reactor_test.mbt pkg.generated.mbti
git commit -m "feat: expose numerical solver diagnostics"
```

### Task 3: Add typed reaction-pattern helpers and selectivity calculations

**Files:**
- Create: `kinetics_extended.mbt`
- Modify: `types.mbt`
- Modify: `moonbit-reactor_test.mbt`

- [ ] **Step 1: Write failing tests for reversible and series reactions**

Add tests for a reversible first-order rate approaching zero at equilibrium, a series reaction whose intermediate selectivity falls as residence time increases, and a parallel reaction whose product yields sum to the limiting-reactant conversion.

- [ ] **Step 2: Run tests and verify RED**

Run `moon test moonbit-reactor_test.mbt --deny-warn`. Expected failure: the reaction-pattern types and functions do not exist.

- [ ] **Step 3: Add typed public data and deterministic helpers**

Add these public types:

```mbt
pub(all) struct ReversibleFirstOrder {
  forward_rate : Double
  reverse_rate : Double
  equilibrium_concentration : Double
} derive(Debug, ToJson)

pub(all) struct SeriesReactionResult {
  intermediate_concentration : Double
  product_concentration : Double
  intermediate_selectivity : Double
} derive(Debug, ToJson)

pub(all) struct ParallelReactionResult {
  product_a_rate : Double
  product_b_rate : Double
  product_a_selectivity : Double
  product_b_selectivity : Double
} derive(Debug, ToJson)
```

Implement `reversible_first_order_rate`, `series_first_order_batch`, and `parallel_first_order_rates`. Clamp non-negative concentrations and rate constants at the API boundary; when total product rate is zero, return zero selectivities. Use closed-form first-order expressions for the series helper and direct rate fractions for the parallel helper so the tests are deterministic and fast.

- [ ] **Step 4: Run the full suite and commit**

Run `moon fmt`, `moon check --deny-warn`, and `moon test --deny-warn`, then commit:

```powershell
git add types.mbt kinetics_extended.mbt moonbit-reactor_test.mbt pkg.generated.mbti
git commit -m "feat: add reaction network kinetics helpers"
```

### Task 4: Add source-traceable benchmark cases and reports

**Files:**
- Create: `benchmark_data.mbt`
- Create: `benchmarks.mbt`
- Modify: `reporting.mbt`
- Modify: `moonbit-reactor_test.mbt`
- Modify: `cmd/main/main.mbt`
- Create: `docs/benchmarks.md`

- [ ] **Step 1: Write failing benchmark registry and CLI tests**

Add tests that the registry has at least five cases, every case has a non-empty source URL/unit/assumption, the first-order analytical case matches `1 - exp(-Da)`, and the CLI report contains the benchmark headings.

- [ ] **Step 2: Run the tests and verify RED**

Run `moon test --deny-warn`. Expected failure: benchmark record types and report functions are absent.

- [ ] **Step 3: Add benchmark records with numeric provenance**

Create a public `BenchmarkCase` record with `id`, `title`, `category`, `source`, `source_url`, `units`, `assumptions`, `expected`, and `tolerance`. Store five offline records in `benchmark_data.mbt`:

1. first-order PFR/CSTR analytical conversion;
2. ethyl acetate saponification, second-order aqueous model;
3. first-order series batch selectivity;
4. exothermic CSTR boundary screening;
5. first-order batch closed-form regression.

Use public source URLs in `docs/benchmarks.md`. Keep measured parameters separate from expected outputs, explain whether each expected value is calculated or transcribed, and record access date `2026-08-10`. Do not claim plant-scale validation.

- [ ] **Step 4: Add offline benchmark execution and stable reports**

Implement `benchmark_cases()`, `run_benchmark(case)`, `benchmark_report_markdown()`, and `benchmark_report_csv()`. The report must include PASS/FAIL, absolute error, tolerance, and source id. Extend `reporting.mbt` with a stable CSV header. Keep `cmd/main` as the existing demo and add a separate `cmd/benchmarks` package whose `main` prints the offline benchmark report; this avoids depending on command-line argument support and gives CI a stable executable target.

- [ ] **Step 5: Run benchmark tests and CLI locally**

Run `moon fmt`, `moon check --deny-warn`, `moon test --deny-warn`, and `moon run cmd/main`. Confirm the CLI is offline and the report includes all five benchmark identifiers.

- [ ] **Step 6: Commit**

```powershell
git add benchmark_data.mbt benchmarks.mbt reporting.mbt moonbit-reactor_test.mbt cmd/main/main.mbt docs/benchmarks.md pkg.generated.mbti
git commit -m "feat: add source-traceable reactor benchmarks"
```

### Task 5: Expand documentation, CI, and acceptance materials

**Files:**
- Modify: `README.mbt.md`
- Modify: `README.md`
- Modify: `docs/DESIGN.md`
- Modify: `docs/OSC2026_CHECKLIST.md`
- Modify: `CHANGELOG.md`
- Modify: `.github/workflows/test.yml`
- Modify: `.gitlink/workflows/ci.yml`

- [ ] **Step 1: Add documentation tests for new public APIs**

Add `mbt check` examples for `residence_time`, a solver report, and one benchmark report call. Run `moon test --update` and review only the intended snapshot changes.

- [ ] **Step 2: Update engineering documentation**

Document model assumptions, source categories, benchmark limitations, boundary behavior, public API additions, and reproducible commands. Update the roadmap from “add more examples” to the completed `v0.2` capabilities and list remaining limits such as no unit algebra, CFD, or multiphase support.

- [ ] **Step 3: Strengthen CI and GitLink workflow**

Ensure both workflows install MoonBit, run `moon fmt --check`, `moon check --deny-warn`, `moon info`, `git diff --exit-code`, `moon test --deny-warn`, `moon test --deny-warn --target native`, and the offline benchmark command. Keep compiler installation platform-aware and do not introduce a virtual contributor.

- [ ] **Step 4: Run the complete validation sequence**

Run:

```powershell
moon fmt --check
moon check --deny-warn --diagnostic-limit 200
moon test --deny-warn --diagnostic-limit 200
moon info
git diff --check
git diff --exit-code -- pkg.generated.mbti
```

Expected result: all checks exit `0`, the test count is at least 40, and the generated interface diff is empty after being reviewed.

- [ ] **Step 5: Commit documentation and CI**

```powershell
git add README.mbt.md README.md docs/DESIGN.md docs/OSC2026_CHECKLIST.md CHANGELOG.md .github/workflows/test.yml .gitlink/workflows/ci.yml pkg.generated.mbti
git commit -m "docs: document v0.2 engineering validation"
```

### Task 6: Publish and verify both repository mirrors

**Files:**
- No source files; Git metadata and remote CI state only.

- [ ] **Step 1: Verify sole-author local history**

Run `git log --format='%an <%ae>' -20` and confirm every GitHub worktree commit uses the GitHub account owner. Use the separate GitLink worktree to preserve the GitLink account owner as the sole author there.

- [ ] **Step 2: Push GitHub and GitLink**

Push the final GitHub `main` branch to `LL124-Arch/moonbit-reactor`. Mirror the source tree into the GitLink clone, rewrite only the GitLink clone's author metadata to the GitLink account owner as done during initial publication, and push `main` to GitLink `master`.

- [ ] **Step 3: Verify remote branches and CI**

Check GitHub visibility/default branch with `gh repo view LL124-Arch/moonbit-reactor --json visibility,defaultBranchRef,url`, inspect the latest Actions run with `gh run list --repo LL124-Arch/moonbit-reactor --limit 3`, and query GitLink repository info/commits with the GitLink CLI. Confirm both remotes expose the same release files and at least 10 commits.

- [ ] **Step 4: Record final release evidence**

Update `CHANGELOG.md` with the release commit and test count, then run the full validation sequence one final time before reporting completion.
