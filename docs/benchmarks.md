# Benchmark Data and Provenance

The benchmark command is offline by design:

```bash
moon run cmd/benchmarks
```

The source URLs below document the parameters or equations used to build the
local records. The executable does not download these pages at test time.

| ID | Category | Source | Data used |
| --- | --- | --- | --- |
| `first-order-pfr-da-1` | analytical | [LibreTexts, section 1.24](https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors) | PFR conversion at `Da = 1` |
| `first-order-cstr-da-1` | analytical | [LibreTexts, section 1.24](https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors) | CSTR conversion at `Da = 1` |
| `ethyl-acetate-saponification-25c` | literature kinetics | [Journal of Chemical Education, 2025](https://doi.org/10.1021/acs.jchemed.5c00554) | `k = 6.523 L mol^-1 min^-1` at `25 C`, `c0 = 0.0100 M` |
| `ethyl-acetate-molecular-weight` | measured property | [NIST Chemistry WebBook, SRD 69](https://webbook.nist.gov/cgi/cbook.cgi?ID=C141786&Units=SI) | `88.1051 g mol^-1`, CAS `141-78-6` |
| `series-first-order-selectivity` | analytical | [LibreTexts teaching material](https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors) | Closed-form `A -> B -> C` regression |
| `exothermic-cstr-screening` | screening | [Project design assumptions](https://github.com/LL124-Arch/moonbit-reactor/blob/main/docs/DESIGN.md) | Declared lumped heat-balance scenario, not plant validation |
| `first-order-batch-da-1` | analytical | [LibreTexts teaching material](https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors) | Closed-form batch oracle at `k t = 1` |

The expected values are stored with the code in `benchmark_data.mbt`. A
benchmark can pass because a value is analytically reproducible, because a
parameter is transcribed from a source, or because it is a declared screening
scenario. These meanings are intentionally kept separate.
