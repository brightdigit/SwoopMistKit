//
//  DeleteRuntimesCommand.swift
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

internal import SwoopMistKit
internal import Foundation
internal import MistKit

/// Deletes only `SimulatorRuntime` records, by names computed from Apple's simulator index.
///
/// A dry run unless `--confirm-delete` is passed, and Development only. Exists so records
/// written with the old `sdkBuildNumbers` list field (brightdigit/MistKit#509) can be removed
/// without `clear`, which deletes every record type.
internal enum DeleteRuntimesCommand {
  internal static func run(_ args: [String]) async throws {
    let loader = ConfigurationLoader()
    let rawConfig = try await loader.loadConfiguration()
    let config = try rawConfig.validated()

    guard config.cloudKit.environment == .development else {
      print("❌ delete-runtimes only runs against the development environment.")
      Foundation.exit(1)
    }

    let confirmed = args.contains("--confirm-delete")

    let authMethod: CloudKitAuthMethod
    if let pemString = config.cloudKit.privateKey {
      authMethod = .pemString(pemString)
    } else {
      authMethod = .pemFile(path: config.cloudKit.privateKeyPath)
    }

    let syncEngine = try SyncEngine(
      containerIdentifier: config.cloudKit.containerID,
      keyID: config.cloudKit.keyID,
      authMethod: authMethod,
      environment: config.cloudKit.environment
    )

    do {
      let deletion = try await syncEngine.deleteSimulatorRuntimes(dryRun: !confirmed)
      print("\nContainer: \(config.cloudKit.containerID) (development, public database)")
      print("Record type: SimulatorRuntime only")
      guard let result = deletion.result else {
        let count = deletion.recordNames.count
        print("DRY RUN: would delete \(count) SimulatorRuntime record name(s).")
        print("Pass --confirm-delete to delete them.")
        return
      }
      print("Sent deletes for \(deletion.recordNames.count) SimulatorRuntime record name(s):")
      print("  🗑️  Deleted:   \(result.deleted)")
      print("  ∅  Not found: \(result.notFound)")
      if !result.failedRecordNames.isEmpty {
        print("  ❌ Failed:    \(result.failedRecordNames.count)")
        print("     \(result.failedRecordNames.prefix(5).joined(separator: ", "))")
        Foundation.exit(1)
      }
    } catch {
      print("\n❌ delete-runtimes failed: \(error.localizedDescription)")
      Foundation.exit(1)
    }
  }
}
