//
//  ConfigurationLoaderTests+SnapshotFlags.swift
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

internal import Testing

@testable import SwoopMistKit

extension ConfigurationLoaderTests {
  /// `export --snapshot` and `--allow-production`, which has no environment variable.
  @Suite("Snapshot Export Flags")
  internal struct SnapshotFlags {
    @Test("export --snapshot reads Development unless --allow-production is passed")
    internal func exportSnapshotAllowProduction() async throws {
      let withoutFlag = ConfigurationLoaderTests.createLoader(
        cliArgs: ["export", "--snapshot", "snapshot.json"],
        env: ["SWOOP_EXPORT_ALLOW_PRODUCTION": "true"]
      )
      let withFlag = ConfigurationLoaderTests.createLoader(
        cliArgs: ["export", "--snapshot", "snapshot.json", "--allow-production"],
        env: [:]
      )

      let defaultConfig = try await withoutFlag.loadConfiguration()
      let allowedConfig = try await withFlag.loadConfiguration()

      #expect(defaultConfig.export?.snapshot == "snapshot.json")
      #expect(defaultConfig.export?.allowProduction == false)
      #expect(allowedConfig.export?.allowProduction == true)
    }

    @Test("--allow-production=false is false")
    internal func allowProductionExplicitFalse() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["export", "--snapshot", "snapshot.json", "--allow-production=false"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.export?.allowProduction == false)
    }
  }
}
