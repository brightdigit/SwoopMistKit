//
//  SimulatorRuntimeBuilder.swift
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

/// Builds `SimulatorRuntimeRecord`s from Apple's simulator index.
///
/// Rules:
/// - One record per platform + runtime build. Duplicate entries (one per architecture
///   set) collapse; duplicates that disagree on label or version are skipped and reported.
/// - The platform comes from the downloadable's `platform` identifier, and the name's OS
///   must agree with it ("xrOS" is visionOS's old name).
/// - The label comes from the name, never from the build number:
///   "… beta N …" is Beta N, "… Release Candidate N …" is RC N, and neither is the final.
///   An unnumbered "beta" takes its number from the downloadable's version
///   ("27.2.0.1" → Beta 1), and an unnumbered "Release Candidate" is RC 1.
/// - Anything else is reported in ``Output/issues`` and skipped. Nothing is guessed.
/// - `sdkBuildNumbers` lists every SDK build `sdkToSimulatorMappings` links to the runtime.
public enum SimulatorRuntimeBuilder {
  /// The parsed records plus the downloadables that were skipped.
  public struct Output: Sendable, Equatable {
    /// One record per platform + runtime build, sorted by platform, version, label
    /// and build.
    public let records: [SimulatorRuntimeRecord]
    /// Downloadables that couldn't become records.
    public let issues: [SimulatorRuntimeIssue]

    public init(records: [SimulatorRuntimeRecord], issues: [SimulatorRuntimeIssue]) {
      self.records = records
      self.issues = issues
    }
  }

  private typealias Platform = SimulatorRuntimeRecord.Platform
  private typealias ReleaseLabel = SimulatorRuntimeRecord.ReleaseLabel

  private struct Key: Hashable {
    let platform: Platform
    let buildNumber: String
  }

  /// `platform` identifiers in the index.
  internal static let platformIdentifiers: [String: SimulatorRuntimeRecord.Platform] = [
    "com.apple.platform.iphoneos": .iOS,
    "com.apple.platform.appletvos": .tvOS,
    "com.apple.platform.watchos": .watchOS,
    "com.apple.platform.xros": .visionOS,
  ]

  /// The OS at the start of a downloadable's name.
  private static let nameOperatingSystems: [String: Platform] = [
    "iOS": .iOS,
    "tvOS": .tvOS,
    "watchOS": .watchOS,
    "visionOS": .visionOS,
    "xrOS": .visionOS,
  ]

  /// The SDK name at the start of an `sdkIdentifier` such as "iphoneos27.2".
  internal static let sdkNames: [String: SimulatorRuntimeRecord.Platform] = [
    "iphoneos": .iOS,
    "appletvos": .tvOS,
    "watchos": .watchOS,
    "xros": .visionOS,
  ]

  private static let betaWord = "beta"
  private static let releaseCandidateWords = "release candidate"
  private static let nameSuffixes: [[String]] = [["Simulator", "Runtime"], ["Simulator"]]

  // MARK: - Building

  /// Parses every downloadable in the index.
  ///
  /// - Parameter index: The decoded index.
  /// - Returns: The records and the skipped downloadables.
  public static func build(from index: SimulatorIndex) -> Output {
    var records: [Key: SimulatorRuntimeRecord] = [:]
    var conflicted: Set<Key> = []
    var issues: [SimulatorRuntimeIssue] = []

    for downloadable in index.downloadables {
      let record: SimulatorRuntimeRecord
      do {
        record = try makeRecord(from: downloadable)
      } catch {
        issues.append(error)
        continue
      }
      let key = Key(platform: record.platform, buildNumber: record.buildNumber)
      guard !conflicted.contains(key) else {
        continue
      }
      if let existing = records[key], existing != record {
        records[key] = nil
        conflicted.insert(key)
        issues.append(
          SimulatorRuntimeIssue(
            buildNumber: record.buildNumber,
            name: downloadable.name,
            reason: .conflictingEntries
          )
        )
        continue
      }
      records[key] = record
    }

    let sdkBuilds = sdkBuildNumbers(from: index.sdkToSimulatorMappings)
    let linked = records.map { key, record in
      var record = record
      record.sdkBuildNumbers = sdkBuilds[key, default: []].sorted()
      return record
    }
    return Output(records: linked.sorted(by: sortOrder), issues: issues)
  }

  /// Maps one downloadable onto a record, without its SDK builds.
  ///
  /// - Throws: ``SimulatorRuntimeIssue`` when the platform or name doesn't parse.
  internal static func makeRecord(
    from downloadable: SimulatorIndex.Downloadable
  ) throws(SimulatorRuntimeIssue) -> SimulatorRuntimeRecord {
    let buildNumber = downloadable.simulatorVersion.buildUpdate
    do throws(SimulatorRuntimeIssue.Reason) {
      guard let platform = platformIdentifiers[downloadable.platform] else {
        throw .unknownPlatform(downloadable.platform)
      }
      let (nameOS, stageWords) = try parseName(downloadable.name)
      guard nameOS == platform else {
        throw .platformMismatch(nameOS.rawValue)
      }
      let label = try releaseLabel(stageWords, downloadableVersion: downloadable.version)
      return SimulatorRuntimeRecord(
        platform: platform,
        version: downloadable.simulatorVersion.version,
        buildNumber: buildNumber,
        releaseLabel: label
      )
    } catch {
      throw SimulatorRuntimeIssue(
        buildNumber: buildNumber,
        name: downloadable.name,
        reason: error
      )
    }
  }

  // MARK: - Names

  /// Splits "iOS 27.2 beta 4 Simulator Runtime" into its OS and the words between the
  /// version and "Simulator" (`["beta", "4"]`).
  private static func parseName(
    _ name: String
  ) throws(SimulatorRuntimeIssue.Reason) -> (Platform, [String]) {
    var words = name.split(separator: " ").map(String.init)
    guard let suffix = nameSuffixes.first(where: { words.ends(with: $0) }) else {
      throw .unparsableName
    }
    words.removeLast(suffix.count)
    guard words.count >= 2,
      let platform = nameOperatingSystems[words[0]],
      isVersion(words[1])
    else {
      throw .unparsableName
    }
    return (platform, Array(words.dropFirst(2)))
  }

  /// Beta N, RC N or final from the words after the version.
  private static func releaseLabel(
    _ stageWords: [String],
    downloadableVersion: String
  ) throws(SimulatorRuntimeIssue.Reason) -> ReleaseLabel {
    guard !stageWords.isEmpty else {
      return .final
    }
    var words = stageWords
    var number: Int?
    if let last = words.last, let value = Int(last) {
      guard value >= 1 else {
        throw .unparsableName
      }
      number = value
      words.removeLast()
    }
    switch words.joined(separator: " ").lowercased() {
    case betaWord:
      if let number {
        return .beta(number)
      }
      guard let seed = betaNumber(fromDownloadableVersion: downloadableVersion) else {
        throw .missingBetaNumber
      }
      return .beta(seed)

    case releaseCandidateWords:
      return .releaseCandidate(number ?? 1)

    default:
      throw .unparsableName
    }
  }

  /// The beta number in a downloadable version's fourth component ("27.2.0.1" → 1).
  private static func betaNumber(fromDownloadableVersion version: String) -> Int? {
    let components = version.split(separator: ".")
    guard components.count == 4, let number = Int(components[3]), (1...99).contains(number)
    else {
      return nil
    }
    return number
  }

  private static func isVersion(_ word: String) -> Bool {
    !word.isEmpty
      && word.split(separator: ".", omittingEmptySubsequences: false)
        .allSatisfy { !$0.isEmpty && $0.allSatisfy(\.isNumber) }
  }

  // MARK: - SDK mappings

  private static func sdkBuildNumbers(
    from mappings: [SimulatorIndex.SDKMapping]
  ) -> [Key: Set<String>] {
    var builds: [Key: Set<String>] = [:]
    for mapping in mappings {
      let sdkName = String(mapping.sdkIdentifier.prefix { $0.isLetter })
      guard let platform = sdkNames[sdkName] else {
        continue
      }
      let key = Key(platform: platform, buildNumber: mapping.simulatorBuildUpdate)
      builds[key, default: []].insert(mapping.sdkBuildUpdate)
    }
    return builds
  }

  // MARK: - Ordering

  private static func sortOrder(
    _ lhs: SimulatorRuntimeRecord,
    _ rhs: SimulatorRuntimeRecord
  ) -> Bool {
    if lhs.platform != rhs.platform {
      return lhs.platform.rawValue < rhs.platform.rawValue
    }
    let lhsVersion = versionComponents(lhs.version)
    let rhsVersion = versionComponents(rhs.version)
    if lhsVersion != rhsVersion {
      return lhsVersion.lexicographicallyPrecedes(rhsVersion)
    }
    if lhs.releaseLabel != rhs.releaseLabel {
      return lhs.releaseLabel < rhs.releaseLabel
    }
    return lhs.buildNumber < rhs.buildNumber
  }

  /// "27.2" → [27, 2, 0]: numeric, padded so "27" equals "27.0".
  private static func versionComponents(_ version: String) -> [Int] {
    let numbers = version.split(separator: ".").map { Int($0) ?? 0 }
    return numbers + Array(repeating: 0, count: max(0, 3 - numbers.count))
  }
}

extension Array where Element: Equatable {
  fileprivate func ends(with suffix: [Element]) -> Bool {
    count >= suffix.count && Array(self[(count - suffix.count)...]) == suffix
  }
}
