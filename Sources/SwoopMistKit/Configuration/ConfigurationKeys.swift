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
internal enum ConfigurationKeys {
  // MARK: - CloudKit Configuration

  /// CloudKit configuration keys
  ///
  /// Auto-generates environment variable names from the key path.
  /// Example: "cloudkit.container_id" → ENV: CLOUDKIT_CONTAINER_ID
  internal enum CloudKit {
    internal static let containerID = ConfigKey<String>(
      "cloudkit.container_id",
      default: "iCloud.com.brightdigit.Swoop"
    )

    internal static let keyID = OptionalConfigKey<String>(
      "cloudkit.key_id"
    )

    internal static let privateKeyPath = OptionalConfigKey<String>(
      "cloudkit.private_key_path"
    )

    internal static let privateKey = OptionalConfigKey<String>(
      "cloudkit.private_key"
    )

    internal static let environment = OptionalConfigKey<String>(
      "cloudkit.environment"
    )
  }

  // MARK: - VirtualBuddy Configuration

  /// VirtualBuddy TSS API configuration keys
  ///
  /// Auto-generates ENV names (VIRTUALBUDDY_API_KEY).
  internal enum VirtualBuddy {
    internal static let apiKey = OptionalConfigKey<String>(
      "virtualbuddy.api_key"
    )
  }

  // MARK: - Fetch Configuration

  /// Fetch throttling configuration keys
  ///
  /// Uses `swoopPrefixed:` to add SWOOP_ prefix to all environment variables.
  /// Example: "fetch.interval_global" → ENV: SWOOP_FETCH_INTERVAL_GLOBAL
  internal enum Fetch {
    /// The minimum interval for every source (`SWOOP_FETCH_INTERVAL_GLOBAL`).
    internal static let intervalGlobal = OptionalConfigKey<Double>(
      swoopPrefixed: "fetch.interval_global"
    )

    /// Generate per-source interval key dynamically
    /// - Parameter source: Data source identifier (e.g., "appledb.dev")
    /// - Returns: An OptionalConfigKey<Double> for the source-specific interval
    internal static func intervalKey(for source: String) -> OptionalConfigKey<Double> {
      let normalized = source.replacingOccurrences(of: ".", with: "_")
      return OptionalConfigKey<Double>(swoopPrefixed: "fetch.interval.\(normalized)")
    }
  }

  // MARK: - Sync Command Configuration

  /// Sync command configuration keys
  ///
  /// Uses `swoopPrefixed:` for SWOOP_SYNC_* environment variables.
  internal enum Sync {
    internal static let dryRun = ConfigKey<Bool>(swoopPrefixed: "sync.dry_run")
    internal static let restoreImagesOnly = ConfigKey<Bool>(
      swoopPrefixed: "sync.restore_images_only"
    )
    internal static let xcodeOnly = ConfigKey<Bool>(swoopPrefixed: "sync.xcode_only")
    internal static let swiftOnly = ConfigKey<Bool>(swoopPrefixed: "sync.swift_only")
    internal static let runtimesOnly = ConfigKey<Bool>(swoopPrefixed: "sync.runtimes_only")
    internal static let noBetas = ConfigKey<Bool>(swoopPrefixed: "sync.no_betas")
    internal static let noAppleWiki = ConfigKey<Bool>(swoopPrefixed: "sync.no_apple_wiki")
    internal static let verbose = ConfigKey<Bool>(swoopPrefixed: "sync.verbose")
    internal static let force = ConfigKey<Bool>(swoopPrefixed: "sync.force")
    internal static let minInterval = OptionalConfigKey<Int>(swoopPrefixed: "sync.min_interval")
    internal static let source = OptionalConfigKey<String>(swoopPrefixed: "sync.source")
    internal static let jsonOutputFile = OptionalConfigKey<String>(
      swoopPrefixed: "sync.json_output_file")
  }

  // MARK: - Export Command Configuration

  /// Export command configuration keys
  ///
  /// Uses `swoopPrefixed:` for SWOOP_EXPORT_* environment variables.
  internal enum Export {
    internal static let output = OptionalConfigKey<String>(swoopPrefixed: "export.output")
    internal static let pretty = ConfigKey<Bool>(swoopPrefixed: "export.pretty")
    internal static let signedOnly = ConfigKey<Bool>(swoopPrefixed: "export.signed_only")
    internal static let noBetas = ConfigKey<Bool>(swoopPrefixed: "export.no_betas")
    internal static let verbose = ConfigKey<Bool>(swoopPrefixed: "export.verbose")
  }

  // MARK: - Status Command Configuration

  /// Status command configuration keys
  ///
  /// Uses `swoopPrefixed:` for SWOOP_STATUS_* environment variables.
  internal enum Status {
    internal static let errorsOnly = ConfigKey<Bool>(swoopPrefixed: "status.errors_only")
    internal static let detailed = ConfigKey<Bool>(swoopPrefixed: "status.detailed")
  }

  // MARK: - List Command Configuration

  /// List command configuration keys
  ///
  /// Uses `swoopPrefixed:` for SWOOP_LIST_* environment variables.
  internal enum List {
    internal static let restoreImages = ConfigKey<Bool>(swoopPrefixed: "list.restore_images")
    internal static let xcodeVersions = ConfigKey<Bool>(swoopPrefixed: "list.xcode_versions")
    internal static let swiftVersions = ConfigKey<Bool>(swoopPrefixed: "list.swift_versions")
  }

  // MARK: - Clear Command Configuration

  /// Clear command configuration keys
  ///
  /// Uses `swoopPrefixed:` for SWOOP_CLEAR_* environment variables.
  internal enum Clear {
    internal static let yes = ConfigKey<Bool>(swoopPrefixed: "clear.yes")
    internal static let verbose = ConfigKey<Bool>(swoopPrefixed: "clear.verbose")
  }
}
