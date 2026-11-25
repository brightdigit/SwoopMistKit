//
//  AppleSDKCorrectionRuleTests.swift
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

/// The correction rules against hand-made Apple indexes: when Apple's index doesn't
/// give a single answer, nothing is guessed.
@Suite("SDK correction rules")
internal struct AppleSDKCorrectionRuleTests {
  private static func day(_ value: Int) -> Date {
    Date(timeIntervalSince1970: TimeInterval(value) * 86_400)
  }

  // MARK: - Helpers

  private static func appearance(
    _ version: String,
    _ build: String,
    xcode xcodeBuild: String,
    day dayValue: Int,
    label: String? = nil,
    platform: SDKVersionRecord.Platform = .iOS
  ) -> SDKAppearance {
    SDKAppearance(
      platform: platform,
      version: version,
      buildNumber: build,
      xcodeRecordName: "XcodeVersion-\(xcodeBuild)",
      xcodeReleaseDate: day(dayValue),
      xcodeIsPrerelease: label != nil,
      xcodePrereleaseLabel: label
    )
  }

  /// One SDK build in a hand-made Apple index (iOS 27.2 unless given).
  private static func sdk(
    _ build: String,
    _ stage: AppleSDKIndex.Stage?,
    seed: Int? = nil
  ) -> AppleSDKIndex.SDK {
    AppleSDKIndex.SDK(
      platform: .iOS,
      buildNumber: build,
      version: "27.2",
      seedNumber: seed,
      stage: stage
    )
  }

  @Test("An unknown build with more than one Apple candidate is kept and reported")
  internal func ambiguousBuildKept() {
    let apple = AppleSDKIndex(sdks: [Self.sdk("24B8118", .final), Self.sdk("24B8119", .final)])
    let output = SDKVersionBuilder.build(
      from: [Self.appearance("27.2", "24B118", xcode: "27B52", day: 10)],
      correctedBy: apple
    )
    #expect(output.records.map(\.buildNumber) == ["24B118"])
    #expect(output.replacedRecordNames.isEmpty)
    #expect(output.conflicts.map(\.kind) == [.buildNotInAppleIndex])
  }

  @Test("A candidate of another stage, or one xcodereleases already names, isn't used")
  internal func candidateMustMatchStage() {
    let apple = AppleSDKIndex(sdks: [
      Self.sdk("24B113", .final), Self.sdk("24B114", .releaseCandidate),
    ])
    let output = SDKVersionBuilder.build(
      from: [
        Self.appearance("27.2", "24B113", xcode: "27B48", day: 5, label: "RC 1"),
        Self.appearance("27.2", "24B118", xcode: "27B52", day: 10),
      ],
      correctedBy: apple
    )
    #expect(Set(output.records.map(\.buildNumber)) == ["24B113", "24B118"])
    #expect(output.conflicts.map(\.kind) == [.buildNotInAppleIndex])
  }

  @Test("A platform version Apple doesn't list isn't compared")
  internal func unlistedVersionIgnored() {
    let apple = AppleSDKIndex(sdks: [Self.sdk("24B8118", .final)])
    let output = SDKVersionBuilder.build(
      from: [
        Self.appearance("27.1", "24A999", xcode: "27A1", day: 1),
        Self.appearance("27.2", "24B118", xcode: "27B52", day: 2, platform: .macOS),
      ],
      correctedBy: apple
    )
    #expect(output.conflicts.isEmpty)
    #expect(output.records.count == 2)
  }

  @Test("A seed on an SDK a final Xcode bundled is reported, and the record stays final")
  internal func seedOnFinalKept() {
    let apple = AppleSDKIndex(sdks: [Self.sdk("24B5109a", .beta, seed: 4)])
    let output = SDKVersionBuilder.build(
      from: [Self.appearance("27.2", "24B5109a", xcode: "27B52", day: 10)],
      correctedBy: apple
    )
    #expect(output.records.first?.isPrerelease == false)
    #expect(output.records.first?.prereleaseLabel == nil)
    #expect(output.conflicts.map(\.kind) == [.seedOnFinal(seedNumber: 4)])
  }
}
