//
//  DataSourcePipeline+SimulatorIndex.swift
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

internal import SwoopKit
internal import Foundation

// MARK: - Apple's simulator index
extension DataSourcePipeline {
  /// Fetch Apple's simulator index: its runtime builds, and the SDK builds that correct
  /// xcodereleases.com.
  ///
  /// It's fetched when runtimes or SDK records are synced. Downloadables whose name
  /// doesn't parse are printed and skipped, never guessed.
  internal func fetchSimulatorIndex(
    options: Options
  ) async throws -> (runtimes: [SimulatorRuntimeRecord], sdks: AppleSDKIndex) {
    let needsSDKs = options.includeXcodeVersions && options.includeSDKVersions
    guard options.includeSimulatorRuntimes || needsSDKs else {
      return ([], .empty)
    }

    let indexes = try await fetchWithMetadata(
      source: "devimages-cdn.apple.com",
      recordType: SimulatorRuntimeRecord.cloudKitRecordType,
      options: options
    ) {
      [try await SimulatorIndexFetcher().fetchIndex()]
    }
    guard let index = indexes.first else {
      return ([], .empty)
    }

    let output = SimulatorRuntimeBuilder.build(from: index)
    let records = output.records
    let issues = output.issues
    let sdks = AppleSDKIndex(index: index, runtimes: records)
    guard options.includeSimulatorRuntimes else {
      return ([], sdks)
    }
    if !records.isEmpty {
      let prerelease = records.filter(\.isPrerelease).count
      print("   ✓ Simulator index: \(records.count) runtimes (\(prerelease) prereleases)")
    }
    if !issues.isEmpty {
      print("   ⚠️  Simulator index: skipped \(issues.count) downloadable(s) that didn't parse:")
      for issue in issues {
        print("      • \(issue)")
      }
    }
    return (records, sdks)
  }

  /// Prints every disagreement with Apple's index, so bad upstream data stays visible.
  internal func printConflicts(_ output: SDKVersionBuilder.Output) {
    guard !output.conflicts.isEmpty else {
      return
    }
    print(
      "   ⚠️  SDKs: \(output.conflicts.count) disagreement(s) between xcodereleases.com "
        + "and Apple's simulator index (Apple's wins):"
    )
    for conflict in output.conflicts {
      print("      • \(conflict)")
    }
    for name in output.replacedRecordNames {
      print("      • replaces \(name)")
    }
  }
}
