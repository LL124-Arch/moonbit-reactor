///|
pub fn ethyl_acetate_saponification() -> DesignPoint {
  let reaction = Reaction::new(
    name="ethyl acetate saponification",
    order=Second,
    k_ref=0.111,
    reference_temperature=298.15,
  )
  let feed = Feed::new(
    concentration=0.05,
    volumetric_flow=1.0,
    temperature=298.15,
    heat_capacity_flow=4.18,
  )
  design_cstr(reaction, feed, 120.0)
}

///|
pub fn first_order_series_example() -> Double {
  selectivity_series_first_order(0.18, 0.04, 5.0)
}

///|
pub fn exothermic_cstr_boundary() -> SafetyBoundary {
  let reaction = Reaction::new(
    name="exothermic liquid reaction",
    order=First,
    k_ref=0.08,
    activation_energy=42000.0,
    reference_temperature=330.0,
    reaction_enthalpy=-72000.0,
  )
  let feed = Feed::new(
    concentration=0.8,
    volumetric_flow=1.0,
    temperature=320.0,
    heat_capacity_flow=6500.0,
  )
  find_temperature_boundary(reaction, feed, 60.0, 380.0, thermal_mode=Adiabatic)
}

///|
pub fn demo_report() -> String {
  let saponification = ethyl_acetate_saponification()
  let selectivity = first_order_series_example()
  let boundary = exothermic_cstr_boundary()
  "moonbit-reactor demo\n" +
  "CSTR conversion: \{saponification.conversion}\n" +
  "Series intermediate fraction: \{selectivity}\n" +
  "Max safe CSTR volume: \{boundary.max_safe_volume}\n"
}
