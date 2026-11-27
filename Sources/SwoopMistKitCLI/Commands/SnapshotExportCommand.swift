//
//  SnapshotExportCommand.swift
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

internal import Foundation
internal import SwoopKit
internal import SwoopMistKit

/// `swoopmist export --snapshot <output.json>`: the release-data snapshot an
/// app bundles (Stewed's `Resources/release-data-snapshot.json`).
///
/// Read-only, and Development unless `--allow-production` is passed.
internal enum SnapshotExportCommand {
  internal static func run(
    _ config: ValidatedSwoopMistKitConfiguration,
    outputPath: String
  ) async {
    do {
      try await export(config, outputPath: outputPath)
    } catch {
      FileHandle.standardError.write(Data("❌ Snapshot export failed: \(error)\n".utf8))
      Foundation.exit(1)
    }
  }

  private static func export(
    _ config: ValidatedSwoopMistKitConfiguration,
    outputPath: String
  ) async throws {
    let environment = config.cloudKit.environment
    try ReleaseDataSnapshotExport.validate(
      config.export ?? ExportConfiguration(snapshot: outputPath),
      environment: environment
    )

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
      environment: environment
    )

    print("Exporting release data from CloudKit \(environment.rawValue)…")
    let snapshot = try await syncEngine.exportSnapshot()
    let size = try ReleaseDataSnapshotExport.write(snapshot, to: URL(filePath: outputPath))

    print(
      """
      Wrote \(outputPath) (\(size) bytes), fetchedAt \(snapshot.fetchedAt.ISO8601Format()):
        \(snapshot.sdkVersions.count) SDKVersion
        \(snapshot.xcodeVersions.count) XcodeVersion
        \(snapshot.simulatorRuntimes.count) SimulatorRuntime
      """
    )
  }
}
