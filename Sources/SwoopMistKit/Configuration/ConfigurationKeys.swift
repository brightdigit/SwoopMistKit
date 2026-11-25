//
//  ConfigurationKeys.swift
//  SwoopMistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import ConfigKeyKit
internal import Foundation

/// Configuration keys for reading from providers
///
/// Each key names its command-line flag explicitly (`cli:`). swift-configuration's
/// `CommandLineArgumentsProvider` joins key components with `-` and leaves `_`
/// alone, so a dot-separated key such as `sync.dry_run` would only match
/// `--sync-dry_run`. Command flags drop the command name (`sync --dry-run`,
/// `export --pretty`); a flag shared by commands (`--verbose`, `--no-betas`)
/// sets each command's value, and each command reads only its own.
internal enum ConfigurationKeys {
  // MARK: - CloudKit Configuration

  /// CloudKit configuration keys: `--cloudkit-container-id` and `CLOUDKIT_CONTAINER_ID`, …
  internal enum CloudKit {
    internal static let containerID = ConfigKey<String>(
      cli: "cloudkit-container-id",
      env: "CLOUDKIT_CONTAINER_ID",
      default: "iCloud.com.brightdigit.Swoop"
    )

    internal static let keyID = OptionalConfigKey<String>(
      cli: "cloudkit-key-id",
      env: "CLOUDKIT_KEY_ID"
    )

    internal static let privateKeyPath = OptionalConfigKey<String>(
      cli: "cloudkit-private-key-path",
      env: "CLOUDKIT_PRIVATE_KEY_PATH"
    )

    internal static let privateKey = OptionalConfigKey<String>(
      cli: "cloudkit-private-key",
      env: "CLOUDKIT_PRIVATE_KEY"
    )

    internal static let environment = OptionalConfigKey<String>(
      cli: "cloudkit-environment",
      env: "CLOUDKIT_ENVIRONMENT"
    )
  }

  // MARK: - VirtualBuddy Configuration

  /// VirtualBuddy TSS API configuration keys: `--virtualbuddy-api-key` and `VIRTUALBUDDY_API_KEY`.
  internal enum VirtualBuddy {
    internal static let apiKey = OptionalConfigKey<String>(
      cli: "virtualbuddy-api-key",
      env: "VIRTUALBUDDY_API_KEY"
    )
  }

  // MARK: - Fetch Configuration

  /// Fetch throttling configuration keys
  ///
  /// Example: `--fetch-interval-global` and `SWOOP_FETCH_INTERVAL_GLOBAL`.
  internal enum Fetch {
    /// The minimum interval for every source (`SWOOP_FETCH_INTERVAL_GLOBAL`).
    internal static let intervalGlobal = OptionalConfigKey<Double>(
      swoopPrefixed: "fetch.interval_global",
      cli: "fetch-interval-global"
    )

    /// Generate per-source interval key dynamically
    /// - Parameter source: Data source identifier (e.g., "appledb.dev")
    /// - Returns: The key for `--fetch-interval-appledb-dev` and
    ///   `SWOOP_FETCH_INTERVAL_APPLEDB_DEV`, for example.
    internal static func intervalKey(for source: String) -> OptionalConfigKey<Double> {
      let normalized = source.replacingOccurrences(of: ".", with: "_")
      let flag = normalized.replacingOccurrences(of: "_", with: "-")
      return OptionalConfigKey<Double>(
        swoopPrefixed: "fetch.interval.\(normalized)",
        cli: "fetch-interval-\(flag)"
      )
    }
  }

  // MARK: - Sync Command Configuration

  /// `swoopmist sync` flags, and the `SWOOP_SYNC_*` environment variables.
  internal enum Sync {
    internal static let dryRun = ConfigKey<Bool>(swoopPrefixed: "sync.dry_run", cli: "dry-run")
    internal static let restoreImagesOnly = ConfigKey<Bool>(
      swoopPrefixed: "sync.restore_images_only",
      cli: "restore-images-only"
    )
    internal static let xcodeOnly = ConfigKey<Bool>(
      swoopPrefixed: "sync.xcode_only",
      cli: "xcode-only"
    )
    internal static let swiftOnly = ConfigKey<Bool>(
      swoopPrefixed: "sync.swift_only",
      cli: "swift-only"
    )
    internal static let runtimesOnly = ConfigKey<Bool>(
      swoopPrefixed: "sync.runtimes_only",
      cli: "runtimes-only"
    )
    internal static let noBetas = ConfigKey<Bool>(swoopPrefixed: "sync.no_betas", cli: "no-betas")
    internal static let noAppleWiki = ConfigKey<Bool>(
      swoopPrefixed: "sync.no_apple_wiki",
      cli: "no-apple-wiki"
    )
    internal static let verbose = ConfigKey<Bool>(swoopPrefixed: "sync.verbose", cli: "verbose")
    internal static let force = ConfigKey<Bool>(swoopPrefixed: "sync.force", cli: "force")
    internal static let minInterval = OptionalConfigKey<Int>(
      swoopPrefixed: "sync.min_interval",
      cli: "min-interval"
    )
    internal static let source = OptionalConfigKey<String>(
      swoopPrefixed: "sync.source",
      cli: "source"
    )
    internal static let jsonOutputFile = OptionalConfigKey<String>(
      swoopPrefixed: "sync.json_output_file",
      cli: "json-output-file"
    )
  }

  // MARK: - Export Command Configuration

  /// `swoopmist export` flags, and the `SWOOP_EXPORT_*` environment variables.
  internal enum Export {
    internal static let output = OptionalConfigKey<String>(
      swoopPrefixed: "export.output",
      cli: "output"
    )
    internal static let pretty = ConfigKey<Bool>(swoopPrefixed: "export.pretty", cli: "pretty")
    internal static let signedOnly = ConfigKey<Bool>(
      swoopPrefixed: "export.signed_only",
      cli: "signed-only"
    )
    internal static let noBetas = ConfigKey<Bool>(
      swoopPrefixed: "export.no_betas",
      cli: "no-betas"
    )
    internal static let verbose = ConfigKey<Bool>(swoopPrefixed: "export.verbose", cli: "verbose")
  }

  // MARK: - Status Command Configuration

  /// `swoopmist status` flags, and the `SWOOP_STATUS_*` environment variables.
  internal enum Status {
    internal static let errorsOnly = ConfigKey<Bool>(
      swoopPrefixed: "status.errors_only",
      cli: "errors-only"
    )
    internal static let detailed = ConfigKey<Bool>(
      swoopPrefixed: "status.detailed",
      cli: "detailed"
    )
  }

  // MARK: - List Command Configuration

  /// `swoopmist list` flags, and the `SWOOP_LIST_*` environment variables.
  internal enum List {
    internal static let restoreImages = ConfigKey<Bool>(
      swoopPrefixed: "list.restore_images",
      cli: "restore-images"
    )
    internal static let xcodeVersions = ConfigKey<Bool>(
      swoopPrefixed: "list.xcode_versions",
      cli: "xcode-versions"
    )
    internal static let swiftVersions = ConfigKey<Bool>(
      swoopPrefixed: "list.swift_versions",
      cli: "swift-versions"
    )
  }

  // MARK: - Clear Command Configuration

  /// `swoopmist clear` flags, and the `SWOOP_CLEAR_*` environment variables.
  internal enum Clear {
    internal static let yes = ConfigKey<Bool>(swoopPrefixed: "clear.yes", cli: "yes")
    internal static let verbose = ConfigKey<Bool>(swoopPrefixed: "clear.verbose", cli: "verbose")
  }
}
