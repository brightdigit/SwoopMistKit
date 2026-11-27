//
//  FixtureRecordService.swift
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
internal import MistKit

/// A read-only `RecordManaging` that answers queries from fixed records and
/// remembers which record types were queried.
internal actor FixtureRecordService: RecordManaging {
  private let recordsByType: [String: [RecordInfo]]
  private let failingType: String?
  internal private(set) var queriedTypes: [String] = []
  internal private(set) var batchOperationCount = 0

  internal init(_ recordsByType: [String: [RecordInfo]], failingType: String? = nil) {
    self.recordsByType = recordsByType
    self.failingType = failingType
  }

  /// ``SnapshotFixture``'s records, with `overrides` replacing a type's.
  internal init(overriding overrides: [String: [RecordInfo]] = [:]) {
    var records: [String: [RecordInfo]] = [:]
    for recordType in ["SDKVersion", "XcodeVersion", "SimulatorRuntime"] {
      records[recordType] = SnapshotFixture.recordInfos(recordType: recordType)
    }
    records.merge(overrides) { _, override in override }
    self.init(records)
  }

  internal func queryAllRecords(recordType: String) async throws -> [RecordInfo] {
    queriedTypes.append(recordType)
    if recordType == failingType {
      throw MockCloudKitError.networkError
    }
    return recordsByType[recordType] ?? []
  }

  internal func executeBatchOperations(_ operations: [RecordOperation]) async throws {
    batchOperationCount += 1
  }
}
