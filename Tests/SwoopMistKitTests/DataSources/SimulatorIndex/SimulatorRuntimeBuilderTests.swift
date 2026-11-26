//
//  SimulatorRuntimeBuilderTests.swift
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
internal import Testing

@testable import SwoopMistKit

@Suite("SimulatorRuntime Builder")
internal struct SimulatorRuntimeBuilderTests {
  private typealias Downloadable = SimulatorIndex.Downloadable

  // MARK: - Helpers

  /// A downloadable shaped like the index's, with real names and builds.
  private static func downloadable(
    _ name: String,
    build: String,
    version: String = "27.2",
    downloadableVersion: String = "27.2.0.0",
    platform: String = "com.apple.platform.iphoneos"
  ) -> Downloadable {
    Downloadable(
      name: name,
      platform: platform,
      version: downloadableVersion,
      simulatorVersion: .init(buildUpdate: build, version: version)
    )
  }

  private static func build(_ downloadables: [Downloadable]) -> SimulatorRuntimeBuilder.Output {
    SimulatorRuntimeBuilder.build(from: SimulatorIndex(downloadables: downloadables))
  }

  private static func label(
    _ name: String,
    downloadableVersion: String = "27.2.0.0"
  ) throws -> SimulatorRuntimeRecord.ReleaseLabel {
    try SimulatorRuntimeBuilder.makeRecord(
      from: downloadable(name, build: "24B114", downloadableVersion: downloadableVersion)
    ).releaseLabel
  }

  // MARK: - Labels

  @Test("Release Candidate names are RC 1 and keep a number when there is one")
  internal func releaseCandidates() throws {
    #expect(try Self.label("iOS 27.2 Release Candidate Simulator Runtime") == .releaseCandidate(1))
    #expect(
      try Self.label("iOS 27.2 Release Candidate 2 Simulator Runtime") == .releaseCandidate(2)
    )
  }

  @Test("Numbered betas take the number in the name")
  internal func numberedBeta() throws {
    #expect(
      try Self.label("iOS 27.2 beta 4 Simulator Runtime", downloadableVersion: "27.2.0.4")
        == .beta(4)
    )
  }

  @Test("An unnumbered beta takes its number from the downloadable version")
  internal func unnumberedBeta() throws {
    #expect(
      try Self.label("iOS 27.1 beta Simulator Runtime", downloadableVersion: "27.1.0.1")
        == .beta(1)
    )
  }

  @Test(
    "An unnumbered beta with no beta number in its version is skipped, not guessed",
    arguments: ["27.1.0.0", "27.1", "27.1.0.1568665771"]
  )
  internal func unnumberedBetaWithoutSeed(downloadableVersion: String) {
    #expect(throws: SimulatorRuntimeIssue.self) {
      try Self.label("iOS 27.1 beta Simulator Runtime", downloadableVersion: downloadableVersion)
    }
  }

  @Test(
    "Finals have no stage words, with or without \"Runtime\"",
    arguments: ["iOS 27.2 Simulator Runtime", "iOS 16 Simulator Runtime", "iOS 13.0 Simulator"]
  )
  internal func finals(name: String) throws {
    #expect(try Self.label(name) == .final)
  }

  @Test(
    "Names that don't parse are reported",
    arguments: [
      "iOS 27.2 Golden Master Simulator Runtime",
      "iOS 27.2 beta 0 Simulator Runtime",
      "iOS 27.2 seed 3 Simulator Runtime",
      "iOS 27.2 Simulator Runtime (Duo)",
      "carOS 27.2 Simulator Runtime",
      "iOS Simulator Runtime",
      "",
    ]
  )
  internal func unparsableNames(name: String) {
    let output = Self.build([Self.downloadable(name, build: "24B114")])
    #expect(output.records.isEmpty)
    #expect(
      output.issues
        == [SimulatorRuntimeIssue(buildNumber: "24B114", name: name, reason: .unparsableName)]
    )
  }

  // MARK: - Platforms

  @Test("Platform identifiers map to the four simulator platforms; xrOS is visionOS")
  internal func platforms() throws {
    let cases: [(String, String, SimulatorRuntimeRecord.Platform)] = [
      ("iOS 27.2 Simulator Runtime", "com.apple.platform.iphoneos", .iOS),
      ("tvOS 27.2 Simulator Runtime", "com.apple.platform.appletvos", .tvOS),
      ("watchOS 27.2 Simulator Runtime", "com.apple.platform.watchos", .watchOS),
      ("visionOS 27.2 Simulator Runtime", "com.apple.platform.xros", .visionOS),
      ("xrOS 1 Simulator Runtime", "com.apple.platform.xros", .visionOS),
    ]
    for (name, identifier, platform) in cases {
      let record = try SimulatorRuntimeBuilder.makeRecord(
        from: Self.downloadable(name, build: "1A1", platform: identifier)
      )
      #expect(record.platform == platform)
    }
  }

  @Test("An unknown platform or one that disagrees with the name is reported")
  internal func badPlatforms() {
    let output = Self.build([
      Self.downloadable("iOS 27.2 Simulator Runtime", build: "1A1", platform: "com.apple.car"),
      Self.downloadable(
        "tvOS 27.2 Simulator Runtime", build: "1A2", platform: "com.apple.platform.iphoneos"
      ),
    ])
    #expect(output.records.isEmpty)
    #expect(
      output.issues.map(\.reason) == [.unknownPlatform("com.apple.car"), .platformMismatch("tvOS")])
  }

  // MARK: - Deduplication and SDK builds

  @Test("Duplicate entries for a build collapse into one record")
  internal func duplicates() {
    let entry = Self.downloadable("iOS 26.4 Simulator Runtime", build: "23E244", version: "26.4")
    let output = Self.build([entry, entry])
    #expect(output.records.count == 1)
    #expect(output.issues.isEmpty)
  }

  @Test("Entries for one build that disagree are skipped and reported")
  internal func conflicts() {
    let output = Self.build([
      Self.downloadable("iOS 27.2 Release Candidate Simulator Runtime", build: "24B114"),
      Self.downloadable("iOS 27.2 Simulator Runtime", build: "24B114"),
      Self.downloadable("iOS 27.2 Simulator Runtime", build: "24B114"),
      Self.downloadable("iOS 27.2 Simulator Runtime", build: "24B8117"),
    ])
    #expect(output.records.map(\.buildNumber) == ["24B8117"])
    #expect(output.issues.map(\.reason) == [.conflictingEntries])
  }

  @Test("SDK builds come from the mappings for the same platform, sorted")
  internal func sdkBuilds() {
    let index = SimulatorIndex(
      downloadables: [
        Self.downloadable("iOS 27.2 Simulator Runtime", build: "24B91016s"),
        Self.downloadable("iOS 27.2 Simulator Runtime", build: "24B8117"),
      ],
      sdkToSimulatorMappings: [
        .init(
          sdkBuildUpdate: "24B8118", simulatorBuildUpdate: "24B91016s",
          sdkIdentifier: "iphoneos27.2"),
        .init(
          sdkBuildUpdate: "24B113", simulatorBuildUpdate: "24B91016s", sdkIdentifier: "iphoneos27.2"
        ),
        .init(
          sdkBuildUpdate: "24B8118", simulatorBuildUpdate: "24B8117", sdkIdentifier: "iphoneos27.2"),
        .init(
          sdkBuildUpdate: "99X1", simulatorBuildUpdate: "24B8117", sdkIdentifier: "watchos27.2"),
      ]
    )
    let records = SimulatorRuntimeBuilder.build(from: index).records
    let builds = Dictionary(
      uniqueKeysWithValues: records.map { ($0.buildNumber, $0.sdkBuildNumbers) })
    #expect(builds["24B91016s"] == ["24B113", "24B8118"])
    #expect(builds["24B8117"] == ["24B8118"])
  }

  @Test("Records sort by platform, numeric version, label, then build")
  internal func ordering() {
    let output = Self.build([
      Self.downloadable("iOS 27.10 Simulator Runtime", build: "3A1", version: "27.10"),
      Self.downloadable("iOS 27.2 Simulator Runtime", build: "2A2"),
      Self.downloadable(
        "iOS 27.2 beta 2 Simulator Runtime", build: "2A1", downloadableVersion: "27.2.0.2"
      ),
      Self.downloadable("iOS 27.2 Release Candidate Simulator Runtime", build: "2A0"),
      Self.downloadable(
        "tvOS 27.0 Simulator Runtime", build: "1A1", version: "27.0",
        platform: "com.apple.platform.appletvos"
      ),
    ])
    #expect(output.records.map(\.buildNumber) == ["2A1", "2A0", "2A2", "3A1", "1A1"])
  }
}
