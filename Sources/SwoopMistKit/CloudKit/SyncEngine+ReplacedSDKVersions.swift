//
//  SyncEngine+ReplacedSDKVersions.swift
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

internal import MistKit
internal import SwoopKit

extension SyncEngine {
  /// Delete `SDKVersion` records whose build Apple's index replaced
  ///
  /// Only names the pipeline computed from a corrected build, that exist in CloudKit,
  /// and only after every `SDKVersion` upload succeeded, so the right record is in
  /// place (and prereleases point at it) before the wrong one goes.
  ///
  /// - Returns: The names CloudKit deleted.
  internal func deleteReplacedSDKVersions(
    _ replacedRecordNames: [String],
    existingRecordNames: Set<String>,
    sdkResult: TypeSyncResult
  ) async throws -> [String] {
    let names = replacedRecordNames.filter(existingRecordNames.contains)
    guard !names.isEmpty else {
      return []
    }
    guard sdkResult.failed == 0 else {
      print(
        "   ⚠️  Not deleting \(names.count) replaced SDK version(s): "
          + "\(sdkResult.failed) SDK upload(s) failed"
      )
      return []
    }

    print("   Deleting \(names.count) SDK version(s) replaced by Apple's index...")
    let result = try await cloudKitService.deleteRecords(
      named: names,
      recordType: SDKVersionRecord.cloudKitRecordType
    )
    let failed = Set(result.failedRecordNames)
    for name in names {
      print("   • \(name)\(failed.contains(name) ? " (failed)" : "")")
    }
    return names.filter { !failed.contains($0) }
  }
}
