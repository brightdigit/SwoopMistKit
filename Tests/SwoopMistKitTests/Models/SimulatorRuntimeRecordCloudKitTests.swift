//
//  SimulatorRuntimeRecordCloudKitTests.swift
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
internal import MistKit
internal import Testing

@testable import SwoopMistKit

@Suite("SimulatorRuntime CloudKit mapping")
internal struct SimulatorRuntimeRecordCloudKitTests {
  private static let duoFinal = SimulatorRuntimeRecord(
    platform: .iOS,
    version: "27.2",
    buildNumber: "24B91016s",
    releaseLabel: .final,
    sdkBuildNumbers: ["24B113", "24B8118"]
  )

  private static let singleSDK = SimulatorRuntimeRecord(
    platform: .iOS,
    version: "27.2",
    buildNumber: "24B114",
    releaseLabel: .releaseCandidate(1),
    sdkBuildNumbers: ["24B113"]
  )

  private static let releaseCandidate = SimulatorRuntimeRecord(
    platform: .watchOS,
    version: "27.2",
    buildNumber: "24S116",
    releaseLabel: .releaseCandidate(1)
  )

  private static func recordInfo(_ record: SimulatorRuntimeRecord) -> RecordInfo {
    RecordInfo(
      recordName: record.recordName,
      recordType: SimulatorRuntimeRecord.cloudKitRecordType,
      recordChangeTag: nil,
      fields: record.toCloudKitFields()
    )
  }

  @Test("The record type is SimulatorRuntime")
  internal func recordType() {
    #expect(SimulatorRuntimeRecord.cloudKitRecordType == "SimulatorRuntime")
  }

  @Test("Fields hold the label as text, isPrerelease as INT64 and the SDK builds as text")
  internal func fields() {
    let fields = Self.duoFinal.toCloudKitFields()
    #expect(fields["platform"] == .string(.value("iOS")))
    #expect(fields["version"] == .string(.value("27.2")))
    #expect(fields["buildNumber"] == .string(.value("24B91016s")))
    #expect(fields["isPrerelease"] == .int64(.value(0)))
    #expect(fields["releaseLabel"] == .string(.value("Final")))
    // MistKit#509: a comma-separated STRING under a new name, never a LIST<STRING>.
    #expect(fields["sdkBuildNumbersText"] == .string(.value("24B113,24B8118")))
    #expect(fields["sdkBuildNumbers"] == nil)

    #expect(Self.singleSDK.toCloudKitFields()["sdkBuildNumbersText"] == .string(.value("24B113")))

    let rcFields = Self.releaseCandidate.toCloudKitFields()
    #expect(rcFields["isPrerelease"] == .int64(.value(1)))
    #expect(rcFields["releaseLabel"] == .string(.value("RC 1")))
    #expect(rcFields["sdkBuildNumbersText"] == nil)
    #expect(rcFields["sdkBuildNumbers"] == nil)
  }

  @Test("No field value is a list, so MistKit can decode the responses (MistKit#509)")
  internal func noListFields() {
    for record in [Self.duoFinal, Self.singleSDK, Self.releaseCandidate] {
      for value in record.toCloudKitFields().values {
        if value.isList {
          Issue.record("\(record.recordName) has a list field")
        }
      }
    }
  }

  @Test("Records round-trip through CloudKit fields: several, one and no SDK builds")
  internal func roundTrip() {
    for record in [Self.duoFinal, Self.singleSDK, Self.releaseCandidate] {
      #expect(SimulatorRuntimeRecord.from(recordInfo: Self.recordInfo(record)) == record)
    }
  }

  @Test(
    "SDK build text splits on commas and ignores blanks",
    arguments: [
      (String?.none, [String]()),
      ("", []),
      ("24B113", ["24B113"]),
      ("24B113,24B8118", ["24B113", "24B8118"]),
      (" 24B113 , ,24B8118,", ["24B113", "24B8118"]),
    ]
  )
  internal func sdkBuildText(text: String?, builds: [String]) {
    #expect(SimulatorRuntimeRecord.sdkBuildNumbers(fromText: text) == builds)
  }

  @Test("An empty SDK build text field maps to no SDK builds")
  internal func emptyText() {
    var fields = Self.releaseCandidate.toCloudKitFields()
    fields["sdkBuildNumbersText"] = .string(.value(""))
    let info = RecordInfo(
      recordName: "SimulatorRuntime-watchOS-24S116",
      recordType: "SimulatorRuntime",
      recordChangeTag: nil,
      fields: fields
    )
    #expect(SimulatorRuntimeRecord.from(recordInfo: info)?.sdkBuildNumbers.isEmpty == true)
  }

  @Test("A missing or unknown label doesn't map")
  internal func badLabel() {
    var fields = Self.releaseCandidate.toCloudKitFields()
    fields["releaseLabel"] = .string(.value("Seed 4"))
    let info = RecordInfo(
      recordName: "SimulatorRuntime-watchOS-24S116",
      recordType: "SimulatorRuntime",
      recordChangeTag: nil,
      fields: fields
    )
    #expect(SimulatorRuntimeRecord.from(recordInfo: info) == nil)
  }
}
