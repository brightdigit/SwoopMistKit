//
//  SDKVersionBuilder+AppleIndex.swift
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

// MARK: - Apple's corrections

extension SDKVersionBuilder {
  /// Replaces builds Apple's index doesn't list, when Apple has exactly one candidate.
  internal static func correctBuilds(
    _ appearances: [SDKAppearance],
    using apple: AppleSDKIndex
  ) -> ([SDKAppearance], [SDKVersionConflict]) {
    let xcodereleasesBuilds = Set(
      appearances.map { GroupKey(platform: $0.platform, buildNumber: $0.buildNumber) }
    )
    var conflicts: [GroupKey: SDKVersionConflict] = [:]

    let corrected = appearances.map { appearance -> SDKAppearance in
      let key = GroupKey(platform: appearance.platform, buildNumber: appearance.buildNumber)
      guard apple.sdk(platform: appearance.platform, buildNumber: appearance.buildNumber) == nil
      else {
        return appearance
      }
      let appleVersion = apple.sdks(platform: appearance.platform, version: appearance.version)
      guard !appleVersion.isEmpty else {
        // Apple doesn't list this platform version at all (older SDKs, macOS): nothing
        // to compare with.
        return appearance
      }

      let candidates = appleVersion.filter { sdk in
        sdk.stage == appearance.stage
          && !xcodereleasesBuilds.contains(
            GroupKey(platform: sdk.platform, buildNumber: sdk.buildNumber)
          )
      }
      guard candidates.count == 1, let replacement = candidates.first else {
        conflicts[key] =
          conflicts[key]
          ?? SDKVersionConflict(
            appearance: appearance,
            kind: .buildNotInAppleIndex
          )
        return appearance
      }

      conflicts[key] =
        conflicts[key]
        ?? SDKVersionConflict(
          appearance: appearance,
          kind: .buildReplaced(appleBuild: replacement.buildNumber)
        )
      return appearance.replacingBuild(with: replacement.buildNumber)
    }

    let ordered = conflicts.values.sorted { $0.description < $1.description }
    return (corrected, ordered)
  }

  /// Gives prerelease records Apple's seed number as their label.
  internal static func correctLabels(
    _ records: [SDKVersionRecord],
    using apple: AppleSDKIndex
  ) -> ([SDKVersionRecord], [SDKVersionConflict]) {
    var conflicts: [SDKVersionConflict] = []
    let corrected = records.map { record -> SDKVersionRecord in
      guard
        let seed = apple.sdk(platform: record.platform, buildNumber: record.buildNumber)?
          .seedNumber
      else {
        return record
      }
      guard record.isPrerelease else {
        conflicts.append(
          SDKVersionConflict(record: record, kind: .seedOnFinal(seedNumber: seed))
        )
        return record
      }
      let label = "Beta \(seed)"
      guard record.prereleaseLabel != label else {
        return record
      }
      conflicts.append(
        SDKVersionConflict(
          record: record,
          kind: .labelReplaced(xcodereleases: record.prereleaseLabel, apple: label)
        )
      )
      var relabelled = record
      relabelled.prereleaseLabel = label
      return relabelled
    }
    return (corrected, conflicts)
  }

  /// Names of records whose build was replaced, unless another Xcode still names that build.
  internal static func replacedRecordNames(
    _ conflicts: [SDKVersionConflict],
    keeping records: [SDKVersionRecord]
  ) -> [String] {
    let kept = Set(records.map(\.recordName))
    let replaced = conflicts.compactMap { conflict -> String? in
      guard case .buildReplaced = conflict.kind else {
        return nil
      }
      return SDKVersionRecord(
        platform: conflict.platform,
        version: conflict.version,
        buildNumber: conflict.buildNumber,
        isPrerelease: false,
        releaseDate: .distantPast
      ).recordName
    }
    return Set(replaced).subtracting(kept).sorted()
  }
}
