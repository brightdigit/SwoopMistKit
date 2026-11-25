# CLI flag names

- swift-configuration's `CommandLineArgumentsProvider` encodes a key's components joined with `-` and only converts camelCase, so ConfigKeyKit's default dot-separated key `sync.dry_run` becomes `--sync-dry_run`. Through 1.0.0-alpha.2 and the alpha.3 work, every documented `swoopmist` flag except `delete-runtimes --confirm-delete` was ignored, and `sync --dry-run` wrote to CloudKit.
- Fixed by naming each flag with `cli:` in `ConfigurationKeys.swift` and reading the command line and the environment with separate `ConfigReader`s (a shared reader also looks `--verbose` up as `VERBOSE`).
- `ConfigurationLoaderTests` builds the loader with `ConfigurationLoader(arguments:environment:)`, the real providers; an `InMemoryProvider` skips the key encoding that hid the bug.
