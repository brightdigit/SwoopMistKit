//
//  SimulatorIndex.swift
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

/// The parts of Apple's simulator index (`index2.dvtdownloadableindex`) that describe
/// runtime builds and SDK builds.
///
/// The index is a public, undocumented property list that Xcode reads to offer simulator
/// runtime downloads. Other keys (`otherDownloadables`, …) are ignored.
public struct SimulatorIndex: Decodable, Sendable, Equatable {
  /// One downloadable runtime.
  public struct Downloadable: Decodable, Sendable, Equatable {
    /// The build and version the runtime installs.
    public struct SimulatorVersion: Decodable, Sendable, Equatable {
      /// The runtime build, such as "24B114".
      public let buildUpdate: String
      /// The runtime version, such as "27.2".
      public let version: String

      public init(buildUpdate: String, version: String) {
        self.buildUpdate = buildUpdate
        self.version = version
      }
    }

    /// Such as "iOS 27.2 Release Candidate Simulator Runtime".
    public let name: String
    /// Such as "com.apple.platform.iphoneos".
    public let platform: String
    /// The downloadable's own version, such as "27.2.0.4". For betas the fourth
    /// component is the beta number.
    public let version: String
    /// The runtime build and version.
    public let simulatorVersion: SimulatorVersion

    public init(
      name: String,
      platform: String,
      version: String,
      simulatorVersion: SimulatorVersion
    ) {
      self.name = name
      self.platform = platform
      self.version = version
      self.simulatorVersion = simulatorVersion
    }
  }

  /// One SDK build to runtime build link. One SDK can map to several runtimes.
  public struct SDKMapping: Decodable, Sendable, Equatable {
    /// The SDK build, such as "24B113".
    public let sdkBuildUpdate: String
    /// The runtime build, such as "24B114".
    public let simulatorBuildUpdate: String
    /// Such as "iphoneos27.2".
    public let sdkIdentifier: String

    public init(sdkBuildUpdate: String, simulatorBuildUpdate: String, sdkIdentifier: String) {
      self.sdkBuildUpdate = sdkBuildUpdate
      self.simulatorBuildUpdate = simulatorBuildUpdate
      self.sdkIdentifier = sdkIdentifier
    }
  }

  /// The seed (beta) number Apple gives one prerelease SDK build.
  public struct SeedMapping: Decodable, Sendable, Equatable {
    /// The SDK build, such as "24B5109a".
    public let buildUpdate: String
    /// Such as "com.apple.platform.iphoneos" or "com.apple.platform.macosx".
    public let platform: String
    /// The seed number: 4 for the fourth beta.
    public let seedNumber: Int

    public init(buildUpdate: String, platform: String, seedNumber: Int) {
      self.buildUpdate = buildUpdate
      self.platform = platform
      self.seedNumber = seedNumber
    }
  }

  private enum CodingKeys: String, CodingKey {
    case downloadables
    case sdkToSimulatorMappings
    case sdkToSeedMappings
  }

  /// Every downloadable runtime. The same build can appear more than once, for example
  /// once per architecture set.
  public let downloadables: [Downloadable]
  /// SDK build to runtime build links.
  public let sdkToSimulatorMappings: [SDKMapping]
  /// Seed numbers of prerelease SDK builds. Finals and RCs aren't listed.
  public let sdkToSeedMappings: [SeedMapping]

  public init(
    downloadables: [Downloadable],
    sdkToSimulatorMappings: [SDKMapping] = [],
    sdkToSeedMappings: [SeedMapping] = []
  ) {
    self.downloadables = downloadables
    self.sdkToSimulatorMappings = sdkToSimulatorMappings
    self.sdkToSeedMappings = sdkToSeedMappings
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.downloadables = try container.decode([Downloadable].self, forKey: .downloadables)
    self.sdkToSimulatorMappings =
      try container.decodeIfPresent([SDKMapping].self, forKey: .sdkToSimulatorMappings) ?? []
    self.sdkToSeedMappings =
      try container.decodeIfPresent([SeedMapping].self, forKey: .sdkToSeedMappings) ?? []
  }

  /// Decodes the index's property list.
  ///
  /// - Parameter data: The contents of `index2.dvtdownloadableindex`.
  /// - Throws: `DecodingError` when the data isn't a property list in this shape.
  public init(propertyList data: Data) throws {
    self = try PropertyListDecoder().decode(Self.self, from: data)
  }
}
