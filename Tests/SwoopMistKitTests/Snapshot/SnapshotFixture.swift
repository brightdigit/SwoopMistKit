//
//  SnapshotFixture.swift
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

/// Fixed CloudKit records for the snapshot export, as a query returns them:
/// out of record-name order, dates with milliseconds, booleans as `INT64`,
/// references and the comma-separated `sdkBuildNumbersText`.
///
/// `Fixtures/release-data-snapshot-stewedtools.json` is what Stewed's
/// `Packages/StewedTools` (`release-data-snapshot`, SwoopMistKit 1.0.0-alpha.3
/// and SwoopCloudKit 1.0.0-beta.1) wrote for these records and ``fetchedAt``.
/// Change neither without regenerating it with that tool.
internal enum SnapshotFixture {
  /// The export's clock: 2025-11-27T12:00:00.750Z, written as whole seconds.
  internal static let fetchedAt = Date(timeIntervalSince1970: 1_764_244_800.75)

  private static let sdkVersions: [RecordInfo] = [
    RecordInfo(
      recordName: "SDKVersion-macOS-25A354",
      recordType: "SDKVersion",
      fields: [
        "platform": .string(.value("macOS")),
        "version": .string(.value("26.0")),
        "buildNumber": .string(.value("25A354")),
        "isPrerelease": .int64(.value(0)),
        "releaseDate": date(1_757_955_600.123),
        "xcodeVersion": reference("XcodeVersion-17A324"),
      ]
    ),
    RecordInfo(
      recordName: "SDKVersion-iOS-23A5318c",
      recordType: "SDKVersion",
      fields: [
        "platform": .string(.value("iOS")),
        "version": .string(.value("26.0")),
        "buildNumber": .string(.value("23A5318c")),
        "isPrerelease": .int64(.value(1)),
        "prereleaseLabel": .string(.value("Beta 6")),
        "releaseDate": date(1_755_619_200),
        "xcodeVersion": reference("XcodeVersion-17A5305k"),
        "supersededBy": reference("SDKVersion-iOS-23A339"),
        "supersededAt": date(1_757_955_600.999),
      ]
    ),
    RecordInfo(
      recordName: "SDKVersion-iOS-23A339",
      recordType: "SDKVersion",
      fields: [
        "platform": .string(.value("iOS")),
        "version": .string(.value("26.0")),
        "buildNumber": .string(.value("23A339")),
        "isPrerelease": .int64(.value(0)),
        "releaseDate": date(1_757_955_600),
        "xcodeVersion": reference("XcodeVersion-17A324"),
      ]
    ),
    RecordInfo(
      recordName: "SDKVersion-watchOS-23R352",
      recordType: "SDKVersion",
      fields: [
        "platform": .string(.value("watchOS")),
        "version": .string(.value("26.0")),
        "buildNumber": .string(.value("23R352")),
        "releaseDate": date(1_757_955_600.5),
      ]
    ),
  ]

  private static let xcodeVersions: [RecordInfo] = [
    RecordInfo(
      recordName: "XcodeVersion-17A5305k",
      recordType: "XcodeVersion",
      fields: [
        "version": .string(.value("17.0")),
        "buildNumber": .string(.value("17A5305k")),
        "releaseDate": date(1_755_619_200.25),
        "isPrerelease": .int64(.value(1)),
        "prereleaseLabel": .string(.value("Beta 6")),
        "sdkVersions": .string(.value("iOS 26.0, macOS 26.0")),
      ]
    ),
    RecordInfo(
      recordName: "XcodeVersion-17A324",
      recordType: "XcodeVersion",
      fields: [
        "version": .string(.value("17.0")),
        "buildNumber": .string(.value("17A324")),
        "releaseDate": date(1_757_955_600),
        "isPrerelease": .int64(.value(0)),
        "downloadURL": .string(
          .value("https://download.developer.apple.com/Developer_Tools/Xcode_26/Xcode_26.xip")
        ),
        "fileSize": .int64(.value(3_012_345_678)),
        "minimumMacOS": reference("RestoreImage-24G84"),
        "includedSwiftVersion": reference("SwiftVersion-6.2"),
        "sdkVersions": .string(.value("iOS 26.0, macOS 26.0, watchOS 26.0")),
        "notes": .string(.value("Release notes with \"quotes\", a slash / and é.")),
      ]
    ),
  ]

  private static let simulatorRuntimes: [RecordInfo] = [
    RecordInfo(
      recordName: "SimulatorRuntime-watchOS-23R5317a",
      recordType: "SimulatorRuntime",
      fields: [
        "platform": .string(.value("watchOS")),
        "version": .string(.value("26.0")),
        "buildNumber": .string(.value("23R5317a")),
        "isPrerelease": .int64(.value(1)),
        "releaseLabel": .string(.value("Beta 3")),
      ]
    ),
    RecordInfo(
      recordName: "SimulatorRuntime-iOS-23A339",
      recordType: "SimulatorRuntime",
      fields: [
        "platform": .string(.value("iOS")),
        "version": .string(.value("26.0")),
        "buildNumber": .string(.value("23A339")),
        "isPrerelease": .int64(.value(0)),
        "releaseLabel": .string(.value("Final")),
        "sdkBuildNumbersText": .string(.value("23A339, 23A340")),
      ]
    ),
  ]

  /// The records of `recordType`, in the order a query returns them.
  internal static func recordInfos(recordType: String) -> [RecordInfo] {
    switch recordType {
    case "SDKVersion":
      sdkVersions
    case "XcodeVersion":
      xcodeVersions
    case "SimulatorRuntime":
      simulatorRuntimes
    default:
      []
    }
  }

  private static func date(_ seconds: TimeInterval) -> FieldValue {
    .date(.value(Date(timeIntervalSince1970: seconds)))
  }

  private static func reference(_ recordName: String) -> FieldValue {
    .reference(.value(Reference(recordName: recordName, action: nil)))
  }
}
