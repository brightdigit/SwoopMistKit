//
//  SimulatorIndexFixtureTests.swift
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

/// Parses a real copy of Apple's simulator index, recorded on 2026-11-17 from
/// <https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex>.
@Suite("Simulator index fixture (2026-11-17)")
internal struct SimulatorIndexFixtureTests {
  private typealias ReleaseLabel = SimulatorRuntimeRecord.ReleaseLabel

  private static let output: SimulatorRuntimeBuilder.Output? = {
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
    return SimulatorRuntimeBuilder.build(from: index)
  }()

  private static func records() throws -> [String: SimulatorRuntimeRecord] {
    let output = try #require(output)
    return Dictionary(uniqueKeysWithValues: output.records.map { ($0.buildNumber, $0) })
  }

  @Test("Every downloadable parses: 447 entries collapse to 354 runtime builds")
  internal func everythingParses() throws {
    let output = try #require(Self.output)
    #expect(output.issues.isEmpty, "\(output.issues)")
    #expect(output.records.count == 354)
  }

  @Test("62 27.x runtimes: 46 betas, 6 RCs and 10 finals")
  internal func release27Counts() throws {
    let records = try #require(Self.output).records.filter { $0.version.hasPrefix("27.") }
    #expect(records.count == 62)
    #expect(records.filter { if case .beta = $0.releaseLabel { true } else { false } }.count == 46)
    #expect(
      records.filter {
        if case .releaseCandidate = $0.releaseLabel { true } else { false }
      }.count == 6
    )
    #expect(records.filter { $0.releaseLabel == .final }.count == 10)
  }

  @Test(
    "27.2 RC runtimes are RC 1, though their builds have no suffix",
    arguments: [
      ("24B114", SimulatorRuntimeRecord.Platform.iOS),
      ("24B91014", .iOS),  // iPhone Duo
      ("24S116", .watchOS),
      ("24K118", .tvOS),
      ("24N118", .visionOS),
    ]
  )
  internal func releaseCandidates(build: String, platform: SimulatorRuntimeRecord.Platform) throws {
    let record = try #require(try Self.records()[build])
    #expect(record.platform == platform)
    #expect(record.version == "27.2")
    #expect(record.releaseLabel == .releaseCandidate(1))
    #expect(record.isPrerelease)
  }

  @Test(
    "27.2 finals, including iPhone Duo's suffixed 24B91016s",
    arguments: ["24B8117", "24B91016s", "24S118", "24K150", "24N120"]
  )
  internal func finals(build: String) throws {
    let record = try #require(try Self.records()[build])
    #expect(record.version == "27.2")
    #expect(record.releaseLabel == .final)
    #expect(!record.isPrerelease)
  }

  @Test("Betas without a suffix are still betas, by the index's names")
  internal func betasWithoutSuffix() throws {
    let records = try Self.records()
    let duoBeta1 = try #require(records["24A94401"])
    #expect(duoBeta1.version == "27.1")
    #expect(duoBeta1.releaseLabel == .beta(1))
    let duoBeta4 = try #require(records["24B91011"])
    #expect(duoBeta4.version == "27.2")
    #expect(duoBeta4.releaseLabel == .beta(4))
  }

  @Test("iPhone Duo's 27.1 runtimes: RC 1 then final")
  internal func duo27Point1() throws {
    let records = try Self.records()
    #expect(records["24A94232"]?.releaseLabel == .releaseCandidate(1))
    #expect(records["24A94425"]?.releaseLabel == .final)
  }

  @Test("One SDK maps to the general and the Duo runtime")
  internal func sharedSDK() throws {
    let records = try Self.records()
    #expect(records["24B8117"]?.sdkBuildNumbers == ["24B8118"])
    #expect(records["24B91016s"]?.sdkBuildNumbers == ["24B113", "24B8118"])
    #expect(records["24B114"]?.sdkBuildNumbers == ["24B113"])
  }

  @Test("Two 27.0 beta 3 builds share a label")
  internal func sharedLabel() throws {
    let records = try Self.records()
    #expect(records["24A5380g"]?.releaseLabel == .beta(3))
    #expect(records["24A5380i"]?.releaseLabel == .beta(3))
  }

  @Test("Older names: xrOS is visionOS, and \"iOS 16\" keeps the index's 16.0")
  internal func olderNames() throws {
    let records = try Self.records()
    let xrOS = try #require(records["21N305"])
    #expect(xrOS.platform == .visionOS)
    #expect(xrOS.version == "1.0")
    #expect(xrOS.releaseLabel == .final)
    #expect(records["20A360"]?.version == "16.0")
  }
}
