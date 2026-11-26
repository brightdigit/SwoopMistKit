# CLAUDE.md

Guidance for Claude Code and other agents working in this repository.

## What this is

SwoopMistKit syncs Apple release data into CloudKit with [MistKit](https://github.com/brightdigit/MistKit): macOS restore images, Xcode versions, Swift versions, SDK versions and simulator runtimes. It fetches them from several public sources, deduplicates them, and writes them to the public database of `iCloud.com.brightdigit.Swoop` with Server-to-Server authentication.

- **Library `SwoopMistKit`**: fetchers, the `DataSourcePipeline`, `SyncEngine`, `SwoopMistKitService`, configuration loading, and the MistKit `CloudKitRecord` conformances for SwoopKit's records.
- **Executable `swoopmist`** (target `SwoopMistKitCLI`): `sync`, `export`, `list`, `status`, `clear` and `delete-runtimes`.
- The record types (`RestoreImageRecord`, `XcodeVersionRecord`, `SwiftVersionRecord`, `SDKVersionRecord`, `SimulatorRuntimeRecord`, `DataSourceMetadata`) live in [SwoopKit](https://github.com/brightdigit/SwoopKit). SwoopMistKit adds CloudKit mapping in `Sources/SwoopMistKit/Extensions/*+CloudKit.swift`.

Consumers: [Stewed](https://github.com/brightdigit/Stewed) (its `StewedTools` package uses `SwoopMistKitService` and the record mappings) and the scheduled sync workflows in this repo.

## Rules

- **Don't change record names or CloudKit field names.** Record names are deterministic (built from build numbers) so repeated syncs update records instead of duplicating them; changing either orphans existing records.
- Swift 6.4 (swift-tools-version 6.4), Swift 6 language mode, complete strict concurrency, `ExistentialAny` and `InternalImportsByDefault`. Every public type is `Sendable`.
- **No `unsafeFlags`** in `Package.swift` (`check-unsafe-flags.yml` enforces it): SwiftPM refuses them in dependencies, and Stewed depends on this package.
- **No swift-docc-plugin in `Package.swift`.** Build docs with `Scripts/docc.sh`.
- MistKit's `FieldValue` carries an arity: write `.string(.value(x))`, match `case .string(.value(let x))`, or use the convenience accessors (`stringValue`, `intValue`, `dateValue`, …). Never write list fields: MistKit can't decode `STRING_LIST` responses yet (brightdigit/MistKit#509), so `SimulatorRuntime.sdkBuildNumbers` is stored as the comma-separated `sdkBuildNumbersText` string.
- Environment variables use the `SWOOP_` prefix (`SWOOP_SYNC_DRY_RUN`, …). The old `BUSHEL_` names are still read, with a deprecation warning (`ConfigKeyPrefix.legacy`, `LegacyEnvironment.swift`). That fallback is deliberate (brightdigit/Stewed#174); keep it. `CLOUDKIT_*` and `VIRTUALBUDDY_API_KEY` have no prefix.
- Every key in `ConfigurationKeys.swift` names its command-line flag with `cli:` (`ConfigKey<Bool>(swoopPrefixed: "sync.dry_run", cli: "dry-run")`). Without it, swift-configuration's `CommandLineArgumentsProvider` reads `sync.dry_run` as `--sync-dry_run`, so the documented `--dry-run` is ignored. Command flags drop the command name; `ConfigurationLoader` reads flags only from the arguments and variables only from the environment. A new flag gets a case in `Tests/SwoopMistKitTests/Configuration/DocumentedFlag.swift` and a mention in the README's command table.
- One type per file; extensions go in `Type+Feature.swift`. Each source file carries the MIT header (`make headers`).

## Commands

```bash
swift build
swift test             # Swift Testing
make lint              # Scripts/lint.sh (tools pinned in mise.toml; run `mise install` once)
make format            # format in place only
make docs              # DocC with --warnings-as-errors; output in .build/docs
make docs-preview

.build/debug/swoopmist sync --dry-run --verbose   # fetch without writing
.build/debug/swoopmist sync --verbose
.build/debug/swoopmist export --output data.json --pretty
.build/debug/swoopmist status
.build/debug/swoopmist delete-runtimes            # Development only; dry run unless --confirm-delete
```

`Scripts/lint.sh` formats in place outside CI, then runs swift-format and SwiftLint, `swift build --build-tests` (locally), the header script and periphery (locally, if installed). Warnings fail only with `LINT_MODE=STRICT`; Sources and Tests still have a backlog of warnings (mostly missing doc comments and explicit ACLs) to clear before strict mode can be the default, as it is in SwoopKit.

### Credentials

```bash
export CLOUDKIT_KEY_ID="your-key-id"
export CLOUDKIT_PRIVATE_KEY_PATH="$HOME/.cloudkit/swoop-private-key.pem"   # or CLOUDKIT_PRIVATE_KEY (PEM text)
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Swoop"                # the default
export CLOUDKIT_ENVIRONMENT="development"
export VIRTUALBUDDY_API_KEY="..."   # optional: TSS signing status, https://tss.virtualbuddy.app/
```

A Server-to-Server key belongs to one container. See `.env.example`.

## Architecture

```
External sources → DataSourcePipeline → SyncEngine → SwoopMistKitService (MistKit) → CloudKit
                      (dedupe, merge,
                       resolve references)
```

- **Fetch**: `DataSourcePipeline` runs the fetchers (ipsw.me, AppleDB, MESU, Mr. Macintosh, xcodereleases.com, swiftversion.net, TheAppleWiki (deprecated), Apple's simulator index, VirtualBuddy TSS) and records `DataSourceMetadata` per source.
- **Transform**: restore images and Xcode versions dedupe by build number, Swift versions by version string. MESU and VirtualBuddy are authoritative for `isSigned`; AppleDB for hashes; otherwise the newest `sourceUpdatedAt` wins. `SDKVersionBuilder` derives `SDKVersion` records from xcodereleases.com and Apple's index (Apple's wins; release days are UTC); a beta SDK's `supersededBy` points at the final SDK. `SimulatorRuntimeBuilder` derives `SimulatorRuntime` records from Apple's `index2.dvtdownloadableindex`; `releaseLabel` is parsed from the runtime name, never the build.
- **Upload**: batches of at most 200 operations, `.forceReplace` with deterministic record names. Order matters for references: SwiftVersion and RestoreImage, then XcodeVersion, then SDKVersion (finals before prereleases), then SimulatorRuntime. A missing referenced record fails with `VALIDATING_REFERENCE_ERROR`.

### CloudKit schema

`schema.ckdb` holds the schema; `Scripts/setup-cloudkit-schema.sh` imports it with `cktool`. Booleans are `INT64` (0/1). `SDKVersion`, `XcodeVersion` and `SimulatorRuntime` grant `READ, CREATE, WRITE` to `_creator` and `READ, CREATE` to `_icloud` (the S2S key needs `CREATE` on `_icloud`), with no `_world` grant. See `.agents/schema-management.md` and `.agents/s2s-auth-details.md`.

## CI

The main workflow (`SwoopMistKit.yml`) triggers on `pull_request` and `workflow_dispatch`, never on `push`. PRs into `main` or a semver branch get the full Apple-platform matrix.

- The manifest needs Swift 6.4, so Linux lanes use the release `swift:6.4-<os>` images and Apple lanes use the `xcode-27` runner image with `/Applications/Xcode_27.2.app` (27.2 simulators; devices iPhone 18 Pro, Apple Watch Ultra 4 (49mm), Apple TV 4K (4th generation), Apple Vision Pro).
- The lint job is pinned to `ubuntu-24.04`: `ubuntu-latest` is Ubuntu 26.04, which lacks the `libxml2.so.2` the SwiftLint binary needs.
- The Documentation job runs `Scripts/docc.sh`; Swift Package Index builds the published docs (`.spi.yml`).
- `dependency-policy.yml` fails PRs into `main` while any dependency is a branch, revision or path. It fails on `simulator` → `main` until MistKit is tagged; don't weaken it.
- `swoopmist-build.yml` builds the Linux binary; `cloudkit-sync-dev.yml` (scheduled) and `cloudkit-sync-prod.yml` (manual) run it through `.github/actions/cloudkit-sync`. See `.github/CLOUDKIT_SYNC_SETUP.md` and `.github/SECRETS_SETUP.md`.
- No CodeQL: it can't analyze Swift 6.4 yet.

## Further reading

- `.agents/implementation-patterns.md`: data-source integration and deduplication details.
- `.agents/s2s-auth-details.md`: Server-to-Server authentication and batch operations.
- `.agents/schema-management.md`: `cktool` and schema changes.
- `.agents/MIGRATION_SWIFT_CONFIGURATION.md`: the move to swift-configuration.

## Memory & Corrections Convention

`AGENTS.md` and `.agents/` are the real files. `CLAUDE.md` and `.claude` are symlinks to them, so Claude Code finds them too. Edit the real paths, and don't replace a symlink with a copy.

- **`.agents/agent-notes.md`**: an append-only log of the maintainer's corrections and standing always/never directives, one line each, newest at the bottom.
- **`.agents/memory/`**: this project's memory store. One markdown file per project-scoped fact, indexed in `.agents/memory/MEMORY.md`.

Read both before doing any work, append to them proactively, replace stale entries rather than leaving both, and never keep project memories in a global memory system.
