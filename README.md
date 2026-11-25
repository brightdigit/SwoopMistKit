# SwoopMistKit

[![SwoopMistKit](https://github.com/brightdigit/SwoopMistKit/actions/workflows/SwoopMistKit.yml/badge.svg)](https://github.com/brightdigit/SwoopMistKit/actions/workflows/SwoopMistKit.yml)
[![Swift 6.4](https://img.shields.io/badge/Swift-6.4-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS%20%7C%20Linux-blue.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

SwoopMistKit syncs Apple OS, Xcode, Swift, SDK and simulator release data into CloudKit with [MistKit](https://github.com/brightdigit/MistKit).

It fetches macOS restore images, Xcode versions, Swift versions, SDK versions and simulator runtimes from several public sources, deduplicates and links them, and writes them to the public database of a CloudKit container (`iCloud.com.brightdigit.Swoop` by default) using Server-to-Server authentication, so no signed-in iCloud user is needed. Apps such as [Stewed](https://github.com/brightdigit/Stewed) read the records back to match the software installed on a Mac.

The package has two products:

- **`SwoopMistKit`**, a library: the fetchers, `DataSourcePipeline`, `SyncEngine`, `SwoopMistKitService` and the MistKit `CloudKitRecord` conformances for [SwoopKit](https://github.com/brightdigit/SwoopKit)'s records.
- **`swoopmist`**, a command-line tool with `sync`, `export`, `list`, `status`, `clear` and `delete-runtimes` commands. The scheduled sync workflows in this repository run it.

## Requirements

- Swift 6.4 (Xcode 27 on macOS, or the `swift:6.4` images on Linux)
- macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, or Linux
- A CloudKit container with the schema in [`schema.ckdb`](schema.ckdb) and a Server-to-Server key for it

## Using the library

```swift
dependencies: [
  .package(url: "https://github.com/brightdigit/SwoopMistKit.git", branch: "simulator")
],
targets: [
  .target(name: "MyTool", dependencies: ["SwoopMistKit"])
]
```

```swift
import SwoopMistKit

let service = try SwoopMistKitService(
  containerIdentifier: "iCloud.com.brightdigit.Swoop",
  keyID: keyID,
  privateKeyPath: privateKeyPath,
  environment: .development
)
let images = try await service.queryAllRecords(recordType: "RestoreImage")
```

Until 1.0 the package tracks branches: SwoopKit's `simulator` and MistKit's `mistico`.

## Using `swoopmist`

```bash
swift build -c release
export CLOUDKIT_KEY_ID="your-key-id"
export CLOUDKIT_PRIVATE_KEY_PATH="$HOME/.cloudkit/swoop-private-key.pem"   # or CLOUDKIT_PRIVATE_KEY with the PEM text
export CLOUDKIT_ENVIRONMENT="development"
export VIRTUALBUDDY_API_KEY="..."   # optional: live signing status from https://tss.virtualbuddy.app/

.build/release/swoopmist sync --dry-run --verbose   # fetch and print, write nothing
.build/release/swoopmist sync --verbose
```

| Command | What it does |
|---------|--------------|
| `sync` | Fetch from every source, deduplicate, and write to CloudKit. `--dry-run`, `--restore-images-only`, `--xcode-only` (Xcode, SDK and simulator runtime records), `--swift-only`, `--no-betas`, `--force` (ignore fetch intervals). `SWOOP_SYNC_RUNTIMES_ONLY=true` syncs only simulator runtimes. |
| `export` | Query CloudKit and write the records as JSON: `--output file.json`, `--pretty`, `--signed-only`, `--no-betas`. |
| `list` | List the records in CloudKit. |
| `status` | Show each data source's last fetch, record count and errors. |
| `clear` | Delete every record SwoopMistKit writes. |
| `delete-runtimes` | Delete only `SimulatorRuntime` records, in Development only; a dry run unless `--confirm-delete`. |

`CLOUDKIT_CONTAINER_ID` defaults to `iCloud.com.brightdigit.Swoop`. The credentials can also be passed as `--cloudkit-key-id`, `--cloudkit-private-key-path` and `--cloudkit-private-key`.

Every other option can be set with an environment variable named `SWOOP_` plus the option's key in capitals, for example `SWOOP_SYNC_DRY_RUN=true` or `SWOOP_FETCH_INTERVAL_GLOBAL=3600`. The names from before the rename (`BUSHEL_SYNC_DRY_RUN`, …) still work, with a deprecation warning, and a `SWOOP_` value wins when both are set. See [`.env.example`](.env.example).

## Data sources

| Source | Provides |
|--------|----------|
| [ipsw.me](https://ipsw.me) (via [IPSWDownloads](https://github.com/brightdigit/IPSWDownloads)) | macOS restore images for VirtualMac2,1 |
| [AppleDB](https://appledb.dev) | Restore images with hashes and signing status |
| Apple MESU | The current signed restore image |
| [Mr. Macintosh](https://mrmacintosh.com) | Restore image archive |
| [VirtualBuddy TSS](https://tss.virtualbuddy.app/) (optional) | Live signing status per restore image |
| [xcodereleases.com](https://xcodereleases.com) | Xcode versions and the SDKs they ship |
| [swiftversion.net](https://swiftversion.net) | Swift versions |
| Apple's simulator index (`index2.dvtdownloadableindex`) | Simulator runtimes, and SDK builds that correct xcodereleases.com |

`sync` deduplicates by build number (restore images, Xcode, SDKs, runtimes) or version (Swift). MESU and VirtualBuddy decide signing status, AppleDB supplies hashes, and Apple's index wins over xcodereleases.com for SDKs. Each source has a minimum fetch interval, tracked in `DataSourceMetadata` records.

## CloudKit records

| Record type | Key | References |
|-------------|-----|------------|
| `RestoreImage` | build number | |
| `SwiftVersion` | version | |
| `XcodeVersion` | build number | `minimumMacOS` → RestoreImage, `includedSwiftVersion` → SwiftVersion |
| `SDKVersion` | platform + build | `xcodeVersion` → XcodeVersion, `supersededBy` → the final SDK (for betas) |
| `SimulatorRuntime` | platform + build | none; `sdkBuildNumbersText` lists its SDK builds |
| `DataSourceMetadata` | source + record type | |

Record names are deterministic and every write is a `.forceReplace`, so repeated syncs update records instead of duplicating them. Records are uploaded in reference order, at most 200 operations per request.

To set up a container, import the schema with [`Scripts/setup-cloudkit-schema.sh`](Scripts/setup-cloudkit-schema.sh) (it uses `xcrun cktool`), then create a Server-to-Server key in the CloudKit Dashboard. A key belongs to one container. The DocC catalog has the full walkthrough: *CloudKit Server-to-Server Authentication Setup*.

## Scheduled sync

GitHub Actions keeps the Development database current:

- [`swoopmist-build.yml`](.github/workflows/swoopmist-build.yml) builds a static Linux `swoopmist` binary.
- [`cloudkit-sync-dev.yml`](.github/workflows/cloudkit-sync-dev.yml) syncs Development three times a day; [`cloudkit-sync-prod.yml`](.github/workflows/cloudkit-sync-prod.yml) syncs Production on demand.

See [`.github/CLOUDKIT_SYNC_SETUP.md`](.github/CLOUDKIT_SYNC_SETUP.md) and [`.github/SECRETS_SETUP.md`](.github/SECRETS_SETUP.md).

## Development

```bash
swift build
swift test
make lint           # Scripts/lint.sh; run `mise install` once for swift-format, SwiftLint and periphery
make format
make docs           # DocC in .build/docs, warnings are errors
make docs-preview
make docker-test    # the tests in swift:6.4-noble
```

There's also a dev container (`.devcontainer`, `swift:6.4-noble`) and an optional XcodeGen project (`make xcode`). Guidance for contributors and coding agents is in [AGENTS.md](AGENTS.md).

CI ([`SwoopMistKit.yml`](.github/workflows/SwoopMistKit.yml)) builds and tests on Ubuntu (noble, plus jammy for PRs into `main`) and on the `xcode-27` runner with Xcode 27.2 (macOS and iOS, plus watchOS, tvOS and visionOS for PRs into `main`), builds the docs, and lints. `dependency-policy.yml` blocks merging into `main` while any dependency is a branch.

## License

MIT. See [LICENSE](LICENSE).
