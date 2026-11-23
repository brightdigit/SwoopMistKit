//
//  AppleSDKIndex.swift
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

/// What Apple's simulator index says about SDK builds.
///
/// `sdkToSeedMappings` gives prerelease SDK builds their seed (beta) number, and
/// `sdkToSimulatorMappings` names each SDK build with its platform version
/// (`iphoneos27.2`) and links it to runtimes, whose names say beta, RC or final.
/// ``SDKVersionBuilder`` uses this to correct xcodereleases.com, which Apple's data
/// overrides wherever the two disagree.
public struct AppleSDKIndex: Sendable, Equatable {
  /// The release stage of an SDK build, without its number.
  public enum Stage: Sendable, Hashable {
    case beta
    case releaseCandidate
    case final
  }

  /// One SDK build Apple's index names.
  public struct SDK: Sendable, Equatable {
    /// The SDK's platform.
    public let platform: SDKVersionRecord.Platform
    /// The SDK build, such as "24B8118".
    public let buildNumber: String
    /// Such as "27.2", or `nil` when only the seed mappings list the build.
    public let version: String?
    /// The seed number, for a prerelease listed in `sdkToSeedMappings`.
    public let seedNumber: Int?
    /// Beta when the build has a seed number, otherwise the stage its runtimes'
    /// names agree on. `nil` when they disagree or no runtime is linked.
    public let stage: Stage?

    /// Creates an SDK entry.
    public init(
      platform: SDKVersionRecord.Platform,
      buildNumber: String,
      version: String?,
      seedNumber: Int?,
      stage: Stage?
    ) {
      self.platform = platform
      self.buildNumber = buildNumber
      self.version = version
      self.seedNumber = seedNumber
      self.stage = stage
    }
  }

  private struct Key: Hashable {
    let platform: SDKVersionRecord.Platform
    let buildNumber: String
  }

  /// An index with no SDK builds, so nothing gets corrected.
  public static let empty = AppleSDKIndex(sdks: [])

  /// Seed mappings also cover the macOS SDK, which has no simulator.
  private static let seedPlatformIdentifiers: [String: SDKVersionRecord.Platform] =
    SimulatorRuntimeBuilder.platformIdentifiers.merging(
      ["com.apple.platform.macosx": .macOS]
    ) { current, _ in current }

  private let sdks: [Key: SDK]

  /// Every SDK build Apple's index names.
  public var allSDKs: [SDK] {
    Array(sdks.values)
  }

  /// - Parameter sdks: SDK builds, one per platform + build.
  public init(sdks: [SDK]) {
    self.sdks = Dictionary(
      sdks.map { (Key(platform: $0.platform, buildNumber: $0.buildNumber), $0) }
    ) { first, _ in first }
  }

  /// Reads the SDK builds out of the index.
  ///
  /// - Parameters:
  ///   - index: The decoded simulator index.
  ///   - runtimes: The runtime records built from the same index, for their labels.
  public init(index: SimulatorIndex, runtimes: [SimulatorRuntimeRecord]) {
    var versions: [Key: String] = [:]
    var runtimeBuilds: [Key: Set<String>] = [:]
    for mapping in index.sdkToSimulatorMappings {
      let sdkName = String(mapping.sdkIdentifier.prefix { $0.isLetter })
      guard let platform = SimulatorRuntimeBuilder.sdkNames[sdkName] else {
        continue
      }
      let key = Key(platform: platform, buildNumber: mapping.sdkBuildUpdate)
      let version = String(mapping.sdkIdentifier.dropFirst(sdkName.count))
      if !version.isEmpty {
        versions[key] = versions[key] ?? version
      }
      runtimeBuilds[key, default: []].insert(mapping.simulatorBuildUpdate)
    }

    var seeds: [Key: Int] = [:]
    for mapping in index.sdkToSeedMappings {
      guard let platform = Self.seedPlatformIdentifiers[mapping.platform] else {
        continue
      }
      seeds[Key(platform: platform, buildNumber: mapping.buildUpdate)] = mapping.seedNumber
    }

    let labels = Dictionary(
      runtimes.map { (Key(platform: $0.platform, buildNumber: $0.buildNumber), $0.releaseLabel) }
    ) { first, _ in first }

    let keys = Set(versions.keys).union(seeds.keys).union(runtimeBuilds.keys)
    self.init(
      sdks: keys.map { key in
        let seed = seeds[key]
        let runtimeStages = Set(
          runtimeBuilds[key, default: []].compactMap { build in
            labels[Key(platform: key.platform, buildNumber: build)].map(Self.stage(of:))
          }
        )
        let stage: Stage? =
          seed != nil ? .beta : (runtimeStages.count == 1 ? runtimeStages.first : nil)
        return SDK(
          platform: key.platform,
          buildNumber: key.buildNumber,
          version: versions[key],
          seedNumber: seed,
          stage: stage
        )
      }
    )
  }

  private static func stage(of label: SimulatorRuntimeRecord.ReleaseLabel) -> Stage {
    switch label {
    case .beta:
      .beta
    case .releaseCandidate:
      .releaseCandidate
    case .final:
      .final
    }
  }

  /// The SDK build Apple's index names, if any.
  public func sdk(platform: SDKVersionRecord.Platform, buildNumber: String) -> SDK? {
    sdks[Key(platform: platform, buildNumber: buildNumber)]
  }

  /// Every SDK build Apple names for one platform version ("27.2" equals "27.2.0").
  public func sdks(platform: SDKVersionRecord.Platform, version: String) -> [SDK] {
    let target = VersionNumber(version)
    return sdks.values.filter { sdk in
      sdk.platform == platform && sdk.version.map(VersionNumber.init) == target
    }
  }
}
