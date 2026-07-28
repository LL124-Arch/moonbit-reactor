// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "LL124-Arch/moonbit-reactor"

version = "0.1.0"

readme = "README.mbt.md"

repository = ""

license = "Apache-2.0"

keywords = [
  "reactor",
  "chemical-engineering",
  "cstr",
  "pfr",
  "batch",
  "numerical-methods",
]

preferred_target = "wasm-gc"

description = "Chemical reactor design toolkit for CSTR, PFR, and batch calculations in MoonBit."
