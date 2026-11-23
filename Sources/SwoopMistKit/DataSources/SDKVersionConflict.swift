//
//  SDKVersionConflict.swift
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

/// One place where xcodereleases.com and Apple's simulator index disagree about an SDK.
///
/// The sync prints each one so bad upstream data stays visible. Apple's index wins:
/// see ``SDKVersionBuilder``.
public struct SDKVersionConflict: Sendable, Equatable, CustomStringConvertible {
  /// What disagrees, and what the sync did about it.
  public enum Kind: Sendable, Equatable {
    /// xcodereleases' build isn't in Apple's index; Apple's only matching build of the
    /// same platform version and stage replaced it.
    case buildReplaced(appleBuild: String)
    /// xcodereleases' build isn't in Apple's index, and Apple has no single build to
    /// replace it with, so it was kept.
    case buildNotInAppleIndex
    /// The prerelease label was replaced by Apple's seed number.
    case labelReplaced(xcodereleases: String?, apple: String)
    /// Apple lists the build as a seed, but a final Xcode bundled it. Kept as a release.
    case seedOnFinal(seedNumber: Int)
  }

  /// The SDK's platform.
  public let platform: SDKVersionRecord.Platform
  /// The SDK version, such as "27.2".
  public let version: String
  /// The build xcodereleases.com gave.
  public let buildNumber: String
  /// The Xcode release that bundled it (`XcodeVersion-<build>`).
  public let xcodeRecordName: String?
  /// What disagrees.
  public let kind: Kind

  /// One line for the sync output.
  public var description: String {
    let subject = "\(platform.rawValue) \(version) SDK \(buildNumber)"
    let xcode = xcodeRecordName.map { " (\($0))" } ?? ""
    switch kind {
    case .buildReplaced(let appleBuild):
      return "\(subject)\(xcode): not in Apple's index; using Apple's \(appleBuild)"
    case .buildNotInAppleIndex:
      return "\(subject)\(xcode): not in Apple's index and no single replacement; kept"
    case .labelReplaced(let xcodereleases, let apple):
      return "\(subject)\(xcode): xcodereleases says \(xcodereleases ?? "no label"), "
        + "Apple's seed says \(apple); using \(apple)"
    case .seedOnFinal(let seedNumber):
      return "\(subject)\(xcode): Apple lists seed \(seedNumber), but a final Xcode "
        + "bundled it; kept as a release"
    }
  }

  /// Creates a conflict.
  public init(
    platform: SDKVersionRecord.Platform,
    version: String,
    buildNumber: String,
    xcodeRecordName: String?,
    kind: Kind
  ) {
    self.platform = platform
    self.version = version
    self.buildNumber = buildNumber
    self.xcodeRecordName = xcodeRecordName
    self.kind = kind
  }
}

extension SDKVersionConflict {
  internal init(appearance: SDKAppearance, kind: Kind) {
    self.init(
      platform: appearance.platform,
      version: appearance.version,
      buildNumber: appearance.buildNumber,
      xcodeRecordName: appearance.xcodeRecordName,
      kind: kind
    )
  }

  internal init(record: SDKVersionRecord, kind: Kind) {
    self.init(
      platform: record.platform,
      version: record.version,
      buildNumber: record.buildNumber,
      xcodeRecordName: record.xcodeVersion,
      kind: kind
    )
  }
}
