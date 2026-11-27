//
//  ReleaseDataSnapshotExportFailureTests.swift
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
internal import Testing

@testable import SwoopMistKit

/// The export fails rather than writing an incomplete snapshot.
@Suite("Release-Data Snapshot Export Failures")
internal struct ReleaseDataSnapshotExportFailureTests {
  @Test(
    "An empty record type fails the export",
    arguments: ["SDKVersion", "XcodeVersion", "SimulatorRuntime"]
  )
  internal func emptyTypeFails(_ recordType: String) async throws {
    let service = FixtureRecordService(overriding: [recordType: []])

    await #expect {
      _ = try await ReleaseDataSnapshotExport.snapshot(from: service)
    } throws: { error in
      guard case .noRecords(let type) = error as? SnapshotExportError else {
        return false
      }
      return type == recordType
    }
  }

  @Test("A record that doesn't map fails the export and is named")
  internal func unmappedRecordFails() async throws {
    var runtimes = SnapshotFixture.recordInfos(recordType: "SimulatorRuntime")
    runtimes.append(
      RecordInfo(
        recordName: "SimulatorRuntime-iOS-BROKEN",
        recordType: "SimulatorRuntime",
        fields: ["platform": .string(.value("iOS"))]
      )
    )
    let service = FixtureRecordService(overriding: ["SimulatorRuntime": runtimes])

    await #expect {
      _ = try await ReleaseDataSnapshotExport.snapshot(from: service)
    } throws: { error in
      guard
        case .unmappedRecords(let recordType, let recordNames) = error as? SnapshotExportError
      else {
        return false
      }
      return recordType == "SimulatorRuntime" && recordNames == ["SimulatorRuntime-iOS-BROKEN"]
    }
  }

  @Test("A failed query fails the export")
  internal func queryFailureFails() async throws {
    var records: [String: [RecordInfo]] = [:]
    for recordType in ["SDKVersion", "XcodeVersion", "SimulatorRuntime"] {
      records[recordType] = SnapshotFixture.recordInfos(recordType: recordType)
    }
    let service = FixtureRecordService(records, failingType: "XcodeVersion")

    await #expect {
      _ = try await ReleaseDataSnapshotExport.snapshot(from: service)
    } throws: { error in
      guard case .query(let recordType, _) = error as? SnapshotExportError else {
        return false
      }
      return recordType == "XcodeVersion"
    }
  }
}
