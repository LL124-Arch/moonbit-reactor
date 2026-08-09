///|
let curated_benchmarks : Array[BenchmarkCase] = [
  {
    id: "first-order-pfr-da-1",
    title: "First-order PFR conversion at Damkohler number 1",
    category: Analytical,
    source: "Chemistry LibreTexts, Tuckerman, section 1.24",
    source_url: "https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors",
    units: "dimensionless conversion",
    assumptions: "constant density, irreversible first-order kinetics, Da = k tau = 1",
    expected: 0.632120558829,
    tolerance: 1.0e-10,
  },
  {
    id: "first-order-cstr-da-1",
    title: "First-order CSTR conversion at Damkohler number 1",
    category: Analytical,
    source: "Chemistry LibreTexts, Tuckerman, section 1.24",
    source_url: "https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors",
    units: "dimensionless conversion",
    assumptions: "constant density, irreversible first-order kinetics, Da = k tau = 1",
    expected: 0.5,
    tolerance: 1.0e-10,
  },
  {
    id: "ethyl-acetate-saponification-25c",
    title: "Ethyl acetate saponification at 25 C",
    category: LiteratureKinetics,
    source: "Journal of Chemical Education 2025, Table 1",
    source_url: "https://doi.org/10.1021/acs.jchemed.5c00554",
    units: "k in L mol^-1 min^-1; concentration in mol L^-1; time in min",
    assumptions: "equal initial reactant concentrations of 0.0100 M, irreversible second-order batch model",
    expected: 0.566085220863,
    tolerance: 1.0e-10,
  },
  {
    id: "ethyl-acetate-molecular-weight",
    title: "Ethyl acetate molecular weight",
    category: MeasuredProperty,
    source: "NIST Chemistry WebBook, SRD 69",
    source_url: "https://webbook.nist.gov/cgi/cbook.cgi?ID=C141786&Units=SI",
    units: "g mol^-1",
    assumptions: "neutral ethyl acetate, CAS 141-78-6",
    expected: 88.1051,
    tolerance: 1.0e-4,
  },
  {
    id: "series-first-order-selectivity",
    title: "First-order series intermediate selectivity",
    category: Analytical,
    source: "Closed-form series-reaction regression derived from first-order kinetics",
    source_url: "https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors",
    units: "dimensionless intermediate selectivity",
    assumptions: "A -> B -> C, cA0 = 1, k1 = 1, k2 = 0.2, batch time = 1",
    expected: 0.891545342122,
    tolerance: 1.0e-10,
  },
  {
    id: "exothermic-cstr-screening",
    title: "Adiabatic exothermic CSTR screening point",
    category: Screening,
    source: "moonbit-reactor declared lumped heat-balance scenario",
    source_url: "https://github.com/LL124-Arch/moonbit-reactor/blob/main/docs/DESIGN.md",
    units: "conversion and K",
    assumptions: "first-order k = 0.03, cA0 = 0.8, tau = 20, DeltaH = -50 kJ mol^-1, heat-capacity flow = 5000",
    expected: 318.0,
    tolerance: 1.0e-6,
  },
  {
    id: "first-order-batch-da-1",
    title: "First-order batch conversion at k t = 1",
    category: Analytical,
    source: "Chemistry LibreTexts first-order PFR relation used as closed-form batch oracle",
    source_url: "https://chem.libretexts.org/Courses/New_York_University/CHEM-UA_652%3A_Thermodynamics_and_Kinetics/01%3A_Lectures/1.24%3A_Plug_flow_reactors_and_comparison_to_continuously_stirred_tank_reactors",
    units: "dimensionless conversion",
    assumptions: "constant volume, irreversible first-order batch kinetics, k t = 1",
    expected: 0.632120558829,
    tolerance: 1.0e-10,
  },
]

///|
pub fn benchmark_cases() -> Array[BenchmarkCase] {
  curated_benchmarks.copy()
}

///|
pub fn benchmark_case(id : String) -> BenchmarkCase? {
  for case in curated_benchmarks {
    if case.id == id {
      break Some(case)
    }
  } nobreak {
    None
  }
}
