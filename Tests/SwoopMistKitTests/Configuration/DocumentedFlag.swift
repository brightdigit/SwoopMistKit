//
//  DocumentedFlag.swift
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

@testable import SwoopMistKit

/// A `swoopmist` flag or option as the README and DocC articles document it,
/// with its environment variable and the configuration value it sets.
internal struct DocumentedFlag: Sendable, CustomStringConvertible {
  /// The command it's documented for (`sync`, `export`, …), or `sync` for a
  /// global option.
  internal let command: String
  /// The flag as typed, with its leading `--`.
  internal let flag: String
  /// The `SWOOP_*` (or `CLOUDKIT_*`, `VIRTUALBUDDY_*`) environment variable.
  internal let environment: String
  /// A value to pass, for an option; `nil` for a boolean flag.
  internal let value: String?
  /// The value the flag sets, as a string, or `nil` when it's unset.
  internal let read: @Sendable (SwoopMistKitConfiguration) -> String?

  internal var description: String {
    "\(command) \(flag)"
  }

  /// A boolean flag such as `sync --dry-run`.
  internal static func bool(
    _ command: String,
    _ flag: String,
    _ environment: String,
    // swiftlint:disable:next discouraged_optional_boolean
    _ read: @escaping @Sendable (SwoopMistKitConfiguration) -> Bool?
  ) -> DocumentedFlag {
    DocumentedFlag(
      command: command,
      flag: flag,
      environment: environment,
      value: nil,
      read: { read($0).map { String($0) } }
    )
  }

  /// An option that takes a value, such as `export --output data.json`.
  internal static func option(
    _ command: String,
    _ flag: String,
    _ environment: String,
    _ value: String,
    _ read: @escaping @Sendable (SwoopMistKitConfiguration) -> String?
  ) -> DocumentedFlag {
    DocumentedFlag(
      command: command,
      flag: flag,
      environment: environment,
      value: value,
      read: read
    )
  }
}

extension DocumentedFlag {
  /// Every boolean flag, by command.
  internal static let booleans: [DocumentedFlag] = [
    .bool("sync", "--dry-run", "SWOOP_SYNC_DRY_RUN") { $0.sync?.dryRun },
    .bool("sync", "--verbose", "SWOOP_SYNC_VERBOSE") { $0.sync?.verbose },
    .bool("sync", "--restore-images-only", "SWOOP_SYNC_RESTORE_IMAGES_ONLY") {
      $0.sync?.restoreImagesOnly
    },
    .bool("sync", "--xcode-only", "SWOOP_SYNC_XCODE_ONLY") { $0.sync?.xcodeOnly },
    .bool("sync", "--swift-only", "SWOOP_SYNC_SWIFT_ONLY") { $0.sync?.swiftOnly },
    .bool("sync", "--runtimes-only", "SWOOP_SYNC_RUNTIMES_ONLY") { $0.sync?.runtimesOnly },
    .bool("sync", "--no-betas", "SWOOP_SYNC_NO_BETAS") { $0.sync?.noBetas },
    .bool("sync", "--no-apple-wiki", "SWOOP_SYNC_NO_APPLE_WIKI") { $0.sync?.noAppleWiki },
    .bool("sync", "--force", "SWOOP_SYNC_FORCE") { $0.sync?.force },
    .bool("export", "--pretty", "SWOOP_EXPORT_PRETTY") { $0.export?.pretty },
    .bool("export", "--signed-only", "SWOOP_EXPORT_SIGNED_ONLY") { $0.export?.signedOnly },
    .bool("export", "--no-betas", "SWOOP_EXPORT_NO_BETAS") { $0.export?.noBetas },
    .bool("export", "--verbose", "SWOOP_EXPORT_VERBOSE") { $0.export?.verbose },
    .bool("status", "--errors-only", "SWOOP_STATUS_ERRORS_ONLY") { $0.status?.errorsOnly },
    .bool("status", "--detailed", "SWOOP_STATUS_DETAILED") { $0.status?.detailed },
    .bool("list", "--restore-images", "SWOOP_LIST_RESTORE_IMAGES") { $0.list?.restoreImages },
    .bool("list", "--xcode-versions", "SWOOP_LIST_XCODE_VERSIONS") { $0.list?.xcodeVersions },
    .bool("list", "--swift-versions", "SWOOP_LIST_SWIFT_VERSIONS") { $0.list?.swiftVersions },
    .bool("clear", "--yes", "SWOOP_CLEAR_YES") { $0.clear?.yes },
    .bool("clear", "--verbose", "SWOOP_CLEAR_VERBOSE") { $0.clear?.verbose },
  ]

  /// Every option that takes a value, by command, then the global options.
  internal static let options: [DocumentedFlag] = [
    .option("sync", "--source", "SWOOP_SYNC_SOURCE", "ipsw.me") { $0.sync?.source },
    .option("sync", "--min-interval", "SWOOP_SYNC_MIN_INTERVAL", "3600") {
      $0.sync?.minInterval.map { String($0) }
    },
    .option("sync", "--json-output-file", "SWOOP_SYNC_JSON_OUTPUT_FILE", "sync-result.json") {
      $0.sync?.jsonOutputFile
    },
    .option("export", "--output", "SWOOP_EXPORT_OUTPUT", "data.json") { $0.export?.output },
    .option("sync", "--cloudkit-key-id", "CLOUDKIT_KEY_ID", "key-id") { $0.cloudKit?.keyID },
    .option("sync", "--cloudkit-private-key-path", "CLOUDKIT_PRIVATE_KEY_PATH", "/k.pem") {
      $0.cloudKit?.privateKeyPath
    },
    .option("sync", "--cloudkit-private-key", "CLOUDKIT_PRIVATE_KEY", "PEM") {
      $0.cloudKit?.privateKey
    },
    .option("sync", "--virtualbuddy-api-key", "VIRTUALBUDDY_API_KEY", "vb-key") {
      $0.virtualBuddy?.apiKey
    },
    .option("sync", "--fetch-interval-global", "SWOOP_FETCH_INTERVAL_GLOBAL", "600.0") {
      $0.fetch?.globalMinimumFetchInterval.map { String($0) }
    },
    .option(
      "sync",
      "--fetch-interval-appledb-dev",
      "SWOOP_FETCH_INTERVAL_APPLEDB_DEV",
      "7200.0"
    ) {
      $0.fetch?.perSourceIntervals["appledb.dev"].map { String($0) }
    },
  ]
}
