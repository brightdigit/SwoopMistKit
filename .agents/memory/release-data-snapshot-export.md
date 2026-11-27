# Release-data snapshot export

- `swoopmist export --snapshot <file.json>` (`ReleaseDataSnapshotExport`, `SnapshotExportCommand`) replaced Stewed's `Packages/StewedTools` `release-data-snapshot` tool (brightdigit/Stewed#194). Its output must stay byte-identical to that tool's for the same records.
- `Tests/SwoopMistKitTests/Fixtures/release-data-snapshot-stewedtools.json` was written by StewedTools' own mapping, sort and encoding (SwoopMistKit 1.0.0-alpha.3, SwoopCloudKit 1.0.0-beta.1) over `SnapshotFixture`'s records. Don't edit either by hand; regenerate the JSON if the fixture changes, or the byte-identity test proves nothing.
- `--allow-production` is a command-line flag only (`ConfigKey<Bool>(cli:default:)`, no `SWOOP_*` variable), so a leftover environment variable can't make the export read Production. It isn't in `DocumentedFlag.booleans` because those tests assume a variable.
- `ReleaseDataSnapshot` and `JSONEncoder.iso8601PrettySorted` come from SwoopKit (1.0.0-beta.2 and later), not SwoopCloudKit.
