//
//  SwoopMistKitService+Delete.swift
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

internal import BushelLogging
internal import Foundation
internal import Logging
public import MistKit

#if canImport(FelinePineSwift)
  internal import FelinePineSwift
#endif

extension SwoopMistKitService {
  /// Delete records of one type by name, without querying for them first
  ///
  /// The names are computed by the caller, so this works even when the records hold
  /// fields MistKit can't decode (brightdigit/MistKit#509): delete responses carry
  /// no fields. A name with no record counts as `notFound`, not as a failure.
  ///
  /// - Parameters:
  ///   - recordNames: The record names to delete
  ///   - recordType: The single record type they belong to
  /// - Returns: How many were deleted, weren't there, or failed
  /// - Throws: `CloudKitError` when a whole batch request fails
  public func deleteRecords(
    named recordNames: [String],
    recordType: String
  ) async throws -> RecordDeletionResult {
    let batchSize = 200
    var result = RecordDeletionResult()

    for start in stride(from: 0, to: recordNames.count, by: batchSize) {
      let names = recordNames[start..<Swift.min(start + batchSize, recordNames.count)]
      let operations = names.map { name in
        RecordOperation(
          operationType: .forceDelete,
          recordType: recordType,
          recordName: name
        )
      }
      print("  Deleting batch of \(operations.count) \(recordType) record(s)...")
      let results = try await service.modifyRecords(
        operations,
        database: .public(.prefers(.serverToServer))
      )
      for recordResult in results {
        switch recordResult {
        case .success:
          result.deleted += 1
        case .failure(let failure) where failure.serverErrorCode == .notFound:
          result.notFound += 1
        case .failure(let failure):
          result.failedRecordNames.append(failure.identifier)
          Self.logger.debug(
            "Delete failed: recordName=\(failure.identifier), code=\(failure.serverErrorCode.rawValue)"
          )
        }
      }
    }
    return result
  }
}
