//
//  SyncEngine+DeleteRuntimes.swift
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

public import SwoopKit
public import MistKit

extension SyncEngine {
  /// Outcome of ``deleteSimulatorRuntimes(dryRun:)``
  public struct RuntimeDeletion: Sendable {
    /// The `SimulatorRuntime` record names computed from Apple's simulator index
    public let recordNames: [String]
    /// What CloudKit did, or `nil` for a dry run
    public let result: RecordDeletionResult?
  }

  /// Delete only `SimulatorRuntime` records, by the names today's simulator index gives
  ///
  /// The record names (`SimulatorRuntime-<platform>-<build>`) come from the same index
  /// the sync builds, so nothing is queried: queries fail while records hold the
  /// `STRING_LIST` field MistKit can't decode (brightdigit/MistKit#509). No other
  /// record type is touched.
  ///
  /// - Parameter dryRun: When `true`, only computes and returns the names.
  /// - Returns: The computed names, and CloudKit's result unless it's a dry run.
  /// - Throws: When the index can't be fetched or a delete request fails.
  public func deleteSimulatorRuntimes(dryRun: Bool) async throws -> RuntimeDeletion {
    let options = DataSourcePipeline.Options(
      includeRestoreImages: false,
      includeXcodeVersions: false,
      includeSwiftVersions: false,
      includeSDKVersions: false,
      includeSimulatorRuntimes: true,
      force: true
    )
    let fetchResult = try await pipeline.fetch(options: options)
    let recordNames = Array(Set(fetchResult.simulatorRuntimes.map(\.recordName))).sorted()

    guard !dryRun else {
      return RuntimeDeletion(recordNames: recordNames, result: nil)
    }

    let result = try await cloudKitService.deleteRecords(
      named: recordNames,
      recordType: SimulatorRuntimeRecord.cloudKitRecordType
    )
    return RuntimeDeletion(recordNames: recordNames, result: result)
  }
}
