//
//  SDKAppearance.swift
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

public import SwoopKit
public import Foundation

/// One SDK as listed inside one Xcode release on xcodereleases.com.
public struct SDKAppearance: Sendable, Equatable {
  /// The SDK's platform.
  public let platform: SDKVersionRecord.Platform
  /// The SDK version, such as "27.2".
  public let version: String
  /// The SDK build xcodereleases.com lists.
  public let buildNumber: String
  /// Record name of the Xcode release that bundled the SDK (`XcodeVersion-<build>`).
  public let xcodeRecordName: String
  /// The Xcode release day, as midnight UTC.
  public let xcodeReleaseDate: Date
  /// Whether the bundling Xcode is a beta or RC.
  public let xcodeIsPrerelease: Bool
  /// "Beta 3", "RC 1", or `nil` for a final Xcode release.
  public let xcodePrereleaseLabel: String?

  /// The bundling Xcode's stage: final, RC (an "RC …" label) or beta.
  internal var stage: AppleSDKIndex.Stage {
    guard xcodeIsPrerelease else {
      return .final
    }
    return xcodePrereleaseLabel?.hasPrefix("RC") == true ? .releaseCandidate : .beta
  }

  /// Creates an appearance.
  public init(
    platform: SDKVersionRecord.Platform,
    version: String,
    buildNumber: String,
    xcodeRecordName: String,
    xcodeReleaseDate: Date,
    xcodeIsPrerelease: Bool,
    xcodePrereleaseLabel: String?
  ) {
    self.platform = platform
    self.version = version
    self.buildNumber = buildNumber
    self.xcodeRecordName = xcodeRecordName
    self.xcodeReleaseDate = xcodeReleaseDate
    self.xcodeIsPrerelease = xcodeIsPrerelease
    self.xcodePrereleaseLabel = xcodePrereleaseLabel
  }

  /// The same appearance with another SDK build.
  internal func replacingBuild(with buildNumber: String) -> SDKAppearance {
    SDKAppearance(
      platform: platform,
      version: version,
      buildNumber: buildNumber,
      xcodeRecordName: xcodeRecordName,
      xcodeReleaseDate: xcodeReleaseDate,
      xcodeIsPrerelease: xcodeIsPrerelease,
      xcodePrereleaseLabel: xcodePrereleaseLabel
    )
  }
}
