# OSC2026 checklist

This repository is shaped for the MoonBit OSC2026 open-source ecosystem competition.

## Official-rule reading notes

- The official site source describes projects as public MoonBit ecosystem work with clear scope, complete documentation, runnable tests, and long-term maintainability.
- The site source lists project proposal materials as participant information, an online repository link, and a one-page PDF proposal.
- It also emphasizes public development with traceable commits, issues, pull requests, and changelog-style progress.
- The current official site source shows a reference MoonBit source scale of 4k to 10k effective lines, with quality, boundaries, and maintainability taking priority.

## Repository self-check

- [x] MoonBit module exists: `moon.mod`.
- [x] Public package exists at the repository root.
- [x] Runnable example exists: `moon run cmd/main`.
- [x] Offline benchmark executable exists: `moon run cmd/benchmarks`.
- [x] Tests exist: `moon test`.
- [x] Test suite covers 40 deterministic cases, including boundary and benchmark checks.
- [x] Strict checks documented and used.
- [x] Solver failures expose explicit diagnostic statuses.
- [x] Benchmark parameters and expected values have source URLs, units, and assumptions.
- [x] Apache-2.0 license exists.
- [x] README describes goals, scope, usage, validation, and roadmap.
- [x] Source statement avoids fake contributors.
- [x] GitHub remote URL filled into `moon.mod`.
- [x] GitLink remote URL filled into project notes after creation.
- [ ] Mooncakes package published after final repository URLs and v0.2 API are stable.

## Repository links

- GitHub: https://github.com/LL124-Arch/moonbit-reactor
- GitLink: https://www.gitlink.org.cn/lll15362196148/moonbit-reactor

## Source and authorship statement

The library is original MoonBit source for reactor-design calculations. AI tools helped draft and iterate code, tests, and documentation, but no virtual contributor identity should be added. GitHub commits should use the GitHub account owner, and GitLink commits should use the GitLink account owner.
