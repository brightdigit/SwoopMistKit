//
//  SDKVersionBuilder.swift
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

public import Foundation
public import SwoopKit

/// Builds `SDKVersionRecord`s from the SDKs listed in each Xcode release.
///
/// Rules:
/// - One record per platform + SDK build.
/// - An SDK build is a **prerelease** only if every Xcode that bundled it was a
///   prerelease. Once a final Xcode ships the same build, it becomes a release.
/// - `releaseDate` is the earliest Xcode release date that bundled the build.
/// - A prerelease is **superseded** by the earliest final SDK on the same platform
///   with the same version. If no same-version release exists, the earliest final
///   SDK with a higher version released on or after the prerelease is used.
///
/// Apple's simulator index wins over xcodereleases.com (``AppleSDKIndex``):
/// - **Builds:** an SDK build Apple doesn't list, for a platform version Apple does list,
///   is replaced by Apple's build of that version and stage (beta, RC or final) that no
///   xcodereleases entry names, when exactly one exists. Otherwise it's kept and reported.
/// - **Labels:** a prerelease SDK that Apple gives a seed number is labelled
///   "Beta <seed>", whatever the bundling Xcode's label says.
/// - Every disagreement is reported in ``Output/conflicts``.
public enum SDKVersionBuilder {
  /// One record per platform + SDK build.
  internal struct GroupKey: Hashable {
    internal let platform: SDKVersionRecord.Platform
    internal let buildNumber: String
  }

  /// The records plus what Apple's index corrected.
  public struct Output: Sendable, Equatable {
    /// One record per platform + SDK build, finals first.
    public let records: [SDKVersionRecord]
    /// Each disagreement with Apple's index, once per platform + build.
    public let conflicts: [SDKVersionConflict]
    /// Names of records a corrected build replaced (such as `SDKVersion-iOS-24B118`),
    /// so the sync can delete them. Never the name of a record in ``records``.
    public let replacedRecordNames: [String]

    /// Creates an output.
    public init(
      records: [SDKVersionRecord],
      conflicts: [SDKVersionConflict] = [],
      replacedRecordNames: [String] = []
    ) {
      self.records = records
      self.conflicts = conflicts
      self.replacedRecordNames = replacedRecordNames
    }
  }

  /// Builds records from xcodereleases.com alone.
  public static func build(from appearances: [SDKAppearance]) -> [SDKVersionRecord] {
    build(from: appearances, correctedBy: .empty).records
  }

  /// Builds records, correcting builds and labels with Apple's index.
  ///
  /// - Parameters:
  ///   - appearances: Every SDK every Xcode release bundled, from xcodereleases.com.
  ///   - apple: SDK builds from Apple's simulator index.
  /// - Returns: The records, the conflicts, and the names of replaced records.
  public static func build(
    from appearances: [SDKAppearance],
    correctedBy apple: AppleSDKIndex
  ) -> Output {
    let (corrected, buildConflicts) = correctBuilds(appearances, using: apple)
    let grouped = Dictionary(grouping: corrected) { appearance in
      GroupKey(platform: appearance.platform, buildNumber: appearance.buildNumber)
    }

    let (records, labelConflicts) = correctLabels(
      grouped.values.compactMap(makeRecord(from:)),
      using: apple
    )
    let sorted = resolveSupersession(records).sorted(by: sortOrder)

    let replaced = replacedRecordNames(buildConflicts, keeping: sorted)

    return Output(
      records: sorted,
      conflicts: buildConflicts + labelConflicts.sorted { $0.description < $1.description },
      replacedRecordNames: replaced
    )
  }

  // MARK: - Grouping

  private static func makeRecord(from group: [SDKAppearance]) -> SDKVersionRecord? {
    let byDate = group.sorted { $0.xcodeReleaseDate < $1.xcodeReleaseDate }
    guard let first = byDate.first else {
      return nil
    }

    let firstFinal = byDate.first { !$0.xcodeIsPrerelease }
    let isPrerelease = firstFinal == nil

    return SDKVersionRecord(
      platform: first.platform,
      version: first.version,
      buildNumber: first.buildNumber,
      isPrerelease: isPrerelease,
      prereleaseLabel: isPrerelease ? first.xcodePrereleaseLabel : nil,
      releaseDate: first.xcodeReleaseDate,
      xcodeVersion: (firstFinal ?? first).xcodeRecordName
    )
  }

  // MARK: - Supersession

  private static func resolveSupersession(_ records: [SDKVersionRecord]) -> [SDKVersionRecord] {
    let finalsByPlatform = Dictionary(grouping: records.filter { !$0.isPrerelease }, by: \.platform)

    return records.map { record in
      guard record.isPrerelease,
        let finals = finalsByPlatform[record.platform],
        let replacement = replacement(for: record, among: finals)
      else {
        return record
      }

      var resolved = record
      resolved.supersededBy = replacement.recordName
      resolved.supersededAt = replacement.releaseDate
      return resolved
    }
  }

  private static func replacement(
    for prerelease: SDKVersionRecord,
    among finals: [SDKVersionRecord]
  ) -> SDKVersionRecord? {
    let target = VersionNumber(prerelease.version)
    let earliestFirst = finals.sorted { $0.releaseDate < $1.releaseDate }

    if let sameVersion = earliestFirst.first(where: { VersionNumber($0.version) == target }) {
      return sameVersion
    }

    return
      earliestFirst
      .filter { VersionNumber($0.version) > target && $0.releaseDate >= prerelease.releaseDate }
      .min { VersionNumber($0.version) < VersionNumber($1.version) }
  }

  private static func sortOrder(_ lhs: SDKVersionRecord, _ rhs: SDKVersionRecord) -> Bool {
    // Final releases first so `supersededBy` targets are uploaded before the
    // prereleases that reference them, then newest first.
    if lhs.isPrerelease != rhs.isPrerelease {
      return !lhs.isPrerelease
    }
    if lhs.releaseDate != rhs.releaseDate {
      return lhs.releaseDate > rhs.releaseDate
    }
    return lhs.recordName < rhs.recordName
  }
}
