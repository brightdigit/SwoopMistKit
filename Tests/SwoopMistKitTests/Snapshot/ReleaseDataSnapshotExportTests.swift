//
//  ReleaseDataSnapshotExportTests.swift
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
internal import SwoopKit
internal import Testing

@testable import SwoopMistKit

@Suite("Release-Data Snapshot Export")
internal struct ReleaseDataSnapshotExportTests {
  private static func stewedToolsOutput() throws -> Data {
    let url = try #require(
      Bundle.module.url(
        forResource: "release-data-snapshot-stewedtools",
        withExtension: "json",
        subdirectory: "Fixtures"
      )
    )
    return try Data(contentsOf: url)
  }

  // MARK: - Byte Identity

  @Test("The JSON is byte-identical to StewedTools' release-data-snapshot")
  internal func matchesStewedTools() async throws {
    let service = FixtureRecordService()

    let snapshot = try await ReleaseDataSnapshotExport.snapshot(
      from: service,
      fetchedAt: SnapshotFixture.fetchedAt
    )
    let data = try ReleaseDataSnapshotExport.encode(snapshot)

    #expect(data == (try Self.stewedToolsOutput()))
  }

  @Test("SwoopKit's encoder matches the one StewedTools used from SwoopCloudKit")
  internal func encoderMatchesReference() async throws {
    // SwoopCloudKit 1.0.0-beta.1's `JSONEncoder.iso8601PrettySorted`, which
    // StewedTools encoded with, then its trailing newline.
    let reference = JSONEncoder()
    reference.dateEncodingStrategy = .iso8601
    reference.outputFormatting = [.prettyPrinted, .sortedKeys]
    let snapshot = try await ReleaseDataSnapshotExport.snapshot(
      from: FixtureRecordService(),
      fetchedAt: SnapshotFixture.fetchedAt
    )

    var expected = try reference.encode(snapshot)
    expected.append(Data("\n".utf8))

    #expect(try ReleaseDataSnapshotExport.encode(snapshot) == expected)
  }

  @Test("write(_:to:) writes the encoded JSON and returns its size")
  internal func writeToFile() async throws {
    let snapshot = try await ReleaseDataSnapshotExport.snapshot(
      from: FixtureRecordService(),
      fetchedAt: SnapshotFixture.fetchedAt
    )
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("snapshot-\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: url) }

    let size = try ReleaseDataSnapshotExport.write(snapshot, to: url)

    let written = try Data(contentsOf: url)
    #expect(size == written.count)
    #expect(written == (try Self.stewedToolsOutput()))
  }

  // MARK: - Records

  @Test("Only SDKVersion, XcodeVersion and SimulatorRuntime are queried, read-only")
  internal func queriesOnlyThreeTypes() async throws {
    let service = FixtureRecordService()

    _ = try await ReleaseDataSnapshotExport.snapshot(from: service)

    #expect(await service.queriedTypes == ["SDKVersion", "XcodeVersion", "SimulatorRuntime"])
    #expect(await service.batchOperationCount == 0)
  }

  @Test("Records are sorted by record name")
  internal func sortedByRecordName() async throws {
    let snapshot = try await ReleaseDataSnapshotExport.snapshot(from: FixtureRecordService())

    #expect(
      snapshot.sdkVersions.map(\.recordName) == [
        "SDKVersion-iOS-23A339",
        "SDKVersion-iOS-23A5318c",
        "SDKVersion-macOS-25A354",
        "SDKVersion-watchOS-23R352",
      ]
    )
    #expect(
      snapshot.xcodeVersions.map(\.recordName) == [
        "XcodeVersion-17A324", "XcodeVersion-17A5305k",
      ]
    )
    #expect(
      snapshot.simulatorRuntimes.map(\.recordName) == [
        "SimulatorRuntime-iOS-23A339", "SimulatorRuntime-watchOS-23R5317a",
      ]
    )
  }

  @Test("fetchedAt is truncated to whole seconds")
  internal func fetchedAtWholeSeconds() async throws {
    let snapshot = try await ReleaseDataSnapshotExport.snapshot(
      from: FixtureRecordService(),
      fetchedAt: Date(timeIntervalSince1970: 1_764_244_800.999)
    )

    #expect(snapshot.fetchedAt == Date(timeIntervalSince1970: 1_764_244_800))
  }

  @Test("More than 200 records of a type are all exported (#17)")
  internal func moreThanTwoHundredRecords() async throws {
    let template = try #require(SnapshotFixture.recordInfos(recordType: "XcodeVersion").first)
    let many = (0..<450).map { index in
      var fields = template.fields
      fields["buildNumber"] = .string(.value(String(format: "17A%04d", index)))
      return RecordInfo(
        recordName: String(format: "XcodeVersion-17A%04d", index),
        recordType: "XcodeVersion",
        fields: fields
      )
    }

    let snapshot = try await ReleaseDataSnapshotExport.snapshot(
      from: FixtureRecordService(overriding: ["XcodeVersion": many.reversed()])
    )

    #expect(snapshot.xcodeVersions.count == 450)
    #expect(snapshot.xcodeVersions.first?.buildNumber == "17A0000")
    #expect(snapshot.xcodeVersions.last?.buildNumber == "17A0449")
  }
}
