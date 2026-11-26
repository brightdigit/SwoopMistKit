# SwoopMistKit config (repo was BushelCloud until 2026-11-24)

The `subrepo` steps below date from the BushelKit subrepo. SwoopMistKit has no
kit path dependency any more, so they don't apply until one comes back.

| Key | Value |
|-----|-------|
| Container root | Parent of worktree dirs (contains `.git`, `trees-bare.git/`) |
| Bare store | `trees-bare.git` |
| `RELEASE_BRANCH` | `v1.0.0-alpha.3` |
| `MAIN_BRANCH` | `main` |
| `MISTKIT_REF` | `1.0.0-beta.6` (tag; `from: "1.0.0-beta.6"` in `Package.swift`; the `v1.0.0-beta.6` branch and `mistico` are retired) |
| `KIT_PACKAGE` | none: BushelKit is no longer a dependency, and SwoopKit resolves by URL (`from: "1.0.0-beta.1"`) |
| `KIT_PATH` | none |
| Primary workflow | `.github/workflows/SwoopMistKit.yml` |
| Build binary workflow | `.github/workflows/swoopmist-build.yml` |
| CloudKit sync action | `.github/actions/cloudkit-sync/action.yml` |

## Expected commit counts

- `v1.0.0-alpha.3` is typically 1 commit ahead of `main`
- `mistkit` / `subrepo` should be 1 commit ahead of release, 2 ahead of `main`

## Backup branches

`backup/mistkit-pre-squash`, `backup/subrepo-pre-squash`

## CelestraCloud variant

Copy this skill folder to CelestraCloud and adjust:

| SwoopMistKit | CelestraCloud |
|-------------|---------------|
| `BushelKit` | `CelestraKit` |
| `SwoopMistKit.yml` | `CelestraCloud.yml` |
| `swoopmist-build.yml` | check for `update-feeds.yml` |
| `v1.0.0-alpha.3` | discover release branch (e.g. `v1.0.0-dev.1-mistkit`) |
