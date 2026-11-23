//
//  AppleSDKCorrectionTests.swift
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
internal import Testing

@testable import SwoopMistKit

/// Apple's simulator index wins over xcodereleases.com (#93, BushelCloud#42).
///
/// Uses the recorded index (2026-11-17) and xcodereleases.com's 27.2 entries as they were
/// on 2026-11-18.
@Suite("SDK corrections from Apple's index")
internal struct AppleSDKCorrectionTests {
  // MARK: - Fixtures

  /// xcodereleases.com's Xcode 27.2 releases, iOS and tvOS SDKs only.
  private static let xcodeReleasesJSON = """
    [
      {
        "date": {"day": 29, "month": 10, "year": 2026}, "name": "Xcode", "requires": "26.6",
        "sdks": {"iOS": [{"build": "24B118", "number": "27.2"}]},
        "version": {"build": "27B52", "number": "27.2", "release": {"release": true}}
      },
      {
        "date": {"day": 19, "month": 10, "year": 2026}, "name": "Xcode", "requires": "26.6",
        "sdks": {"iOS": [{"build": "24B113", "number": "27.2"}]},
        "version": {"build": "27B48", "number": "27.2", "release": {"rc": 1}}
      },
      {
        "date": {"day": 14, "month": 10, "year": 2026}, "name": "Xcode", "requires": "26.6",
        "sdks": {
          "iOS": [{"build": "24B5109a", "number": "27.2"}],
          "tvOS": [{"build": "24K5093g", "number": "27.2"}]
        },
        "version": {"build": "27B5038j", "number": "27.2", "release": {"beta": 3}}
      },
      {
        "date": {"day": 28, "month": 9, "year": 2026}, "name": "Xcode", "requires": "26.6",
        "sdks": {"iOS": [{"build": "24B5089g", "number": "27.2"}]},
        "version": {"build": "27B5028f", "number": "27.2", "release": {"beta": 2}}
      }
    ]
    """

  private static let appleIndex: AppleSDKIndex? = {
    guard
      let url = Bundle.module.url(
        forResource: "index2-2026-11-17",
        withExtension: "dvtdownloadableindex",
        subdirectory: "Fixtures"
      ),
      let data = try? Data(contentsOf: url),
      let index = try? SimulatorIndex(propertyList: data)
    else {
      return nil
    }
    return AppleSDKIndex(index: index, runtimes: SimulatorRuntimeBuilder.build(from: index).records)
  }()

  private static func appearances() throws -> [SDKAppearance] {
    let releases = try JSONDecoder().decode(
      [XcodeReleasesFetcher.XcodeRelease].self,
      from: Data(xcodeReleasesJSON.utf8)
    )
    return XcodeReleasesFetcher.makeOutput(from: releases).sdkAppearances
  }

  private static func corrected() throws -> SDKVersionBuilder.Output {
    SDKVersionBuilder.build(from: try appearances(), correctedBy: try #require(appleIndex))
  }

  private static func record(
    _ output: SDKVersionBuilder.Output,
    _ build: String,
    platform: SDKVersionRecord.Platform = .iOS
  ) -> SDKVersionRecord? {
    output.records.first { $0.platform == platform && $0.buildNumber == build }
  }

  // MARK: - Apple's index

  @Test("The index's seed mappings and SDK versions are read")
  internal func readsAppleIndex() throws {
    let apple = try #require(Self.appleIndex)
    let beta = try #require(apple.sdk(platform: .iOS, buildNumber: "24B5109a"))
    #expect(beta.seedNumber == 4)
    #expect(beta.stage == .beta)
    #expect(beta.version == "27.2")

    let final = try #require(apple.sdk(platform: .iOS, buildNumber: "24B8118"))
    #expect(final.seedNumber == nil)
    #expect(final.stage == .final)

    // 24B113 maps to the RC runtime 24B114 and the iPhone Duo final 24B91016s, so its
    // stage is unknown and it's never a replacement candidate.
    #expect(apple.sdk(platform: .iOS, buildNumber: "24B113")?.version == "27.2")
    #expect(apple.sdk(platform: .iOS, buildNumber: "24B113")?.stage == nil)
    #expect(apple.sdk(platform: .tvOS, buildNumber: "24K5093g")?.seedNumber == 2)
    #expect(apple.sdk(platform: .iOS, buildNumber: "24B118") == nil)
  }

  // MARK: - Builds

  @Test("27.2 final's iOS SDK is Apple's 24B8118, not xcodereleases' 24B118")
  internal func finalBuildReplaced() throws {
    let output = try Self.corrected()
    #expect(Self.record(output, "24B118") == nil)

    let final = try #require(Self.record(output, "24B8118"))
    #expect(final.recordName == "SDKVersion-iOS-24B8118")
    #expect(!final.isPrerelease)
    #expect(final.version == "27.2")
    #expect(final.xcodeVersion == "XcodeVersion-27B52")

    #expect(output.replacedRecordNames == ["SDKVersion-iOS-24B118"])
    #expect(
      output.conflicts.contains(
        SDKVersionConflict(
          platform: .iOS,
          version: "27.2",
          buildNumber: "24B118",
          xcodeRecordName: "XcodeVersion-27B52",
          kind: .buildReplaced(appleBuild: "24B8118")
        )
      )
    )
  }

  @Test("27.2's prereleases are superseded by the corrected final")
  internal func supersededByCorrectedFinal() throws {
    let output = try Self.corrected()
    for build in ["24B113", "24B5109a", "24B5089g"] {
      #expect(Self.record(output, build)?.supersededBy == "SDKVersion-iOS-24B8118", "\(build)")
    }
  }

  @Test("Builds Apple's index lists are never replaced")
  internal func knownBuildsKept() throws {
    let output = try Self.corrected()
    #expect(Self.record(output, "24B113")?.prereleaseLabel == "RC 1")
    #expect(Self.record(output, "24B5089g") != nil)
    #expect(!output.conflicts.contains { $0.buildNumber == "24B113" })
  }

  @Test("Without Apple's index, records are built from xcodereleases alone")
  internal func emptyIndexChangesNothing() throws {
    let appearances = try Self.appearances()
    let output = SDKVersionBuilder.build(from: appearances, correctedBy: .empty)
    #expect(output.records == SDKVersionBuilder.build(from: appearances))
    #expect(output.conflicts.isEmpty)
    #expect(output.replacedRecordNames.isEmpty)
    #expect(output.records.contains { $0.buildNumber == "24B118" })
  }

  // MARK: - Labels

  @Test("27B5038j's iOS SDK 24B5109a is Beta 4 (Apple's seed), not Beta 3")
  internal func seedLabelWins() throws {
    let output = try Self.corrected()
    let beta = try #require(Self.record(output, "24B5109a"))
    #expect(beta.isPrerelease)
    #expect(beta.prereleaseLabel == "Beta 4")
    #expect(
      output.conflicts.contains(
        SDKVersionConflict(
          platform: .iOS,
          version: "27.2",
          buildNumber: "24B5109a",
          xcodeRecordName: "XcodeVersion-27B5038j",
          kind: .labelReplaced(xcodereleases: "Beta 3", apple: "Beta 4")
        )
      )
    )
  }

  @Test("Seeds are per platform: 27B5038j's tvOS SDK is Beta 2")
  internal func seedIsPerPlatform() throws {
    let output = try Self.corrected()
    #expect(Self.record(output, "24K5093g", platform: .tvOS)?.prereleaseLabel == "Beta 2")
  }

  @Test("A label that already matches Apple's seed isn't reported")
  internal func matchingLabelNotReported() throws {
    let output = try Self.corrected()
    let seed = try #require(Self.appleIndex?.sdk(platform: .iOS, buildNumber: "24B5089g"))
    #expect(
      Self.record(output, "24B5089g")?.prereleaseLabel == "Beta \(try #require(seed.seedNumber))")
    #expect(!output.conflicts.contains { $0.buildNumber == "24B5089g" })
  }
}
