# Agent notes

A running log of the maintainer's corrections and standing always/never directives for this repo.

- **Read this file at the start of every session, before doing any work.**
- **Append proactively, without being asked:** whenever the maintainer corrects you or gives an always/never instruction, add one line here.
- One line per entry. Newest lines at the bottom.
- When a directive supersedes an earlier one, update or remove the stale line rather than leaving both.

Project facts that aren't directives (decisions, constraints, gotchas) go in `.agents/memory/` instead; see `.agents/memory/MEMORY.md`.

---

- 2026-11-25: Keep the `BUSHEL_*` environment-variable fallback (`ConfigKeyPrefix.legacy`, `LegacyEnvironment.swift`); it's deliberate (brightdigit/Stewed#174).
- 2026-11-25: Never weaken `dependency-policy.yml`; it guards merges into `main`, and branch dependencies are fine on `simulator`.
