//
//  ConfigurationLoaderTests+EnvironmentVariables.swift
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
  /// Every documented flag's environment variable, including the `BUSHEL_*`
  /// names from before the rename.
  @Suite("Environment Variables")
  internal struct EnvironmentVariables {
    @Test("A SWOOP_ variable sets a boolean", arguments: DocumentedFlag.booleans)
    internal func booleanVariable(_ flag: DocumentedFlag) async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command],
        env: [flag.environment: "true"]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == "true")
    }

    @Test("A variable sets an option", arguments: DocumentedFlag.options)
    internal func optionVariable(_ flag: DocumentedFlag) async throws {
      let value = try #require(flag.value)
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command],
        env: [flag.environment: value]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == value)
    }

    @Test(
      "A BUSHEL_ variable still sets a boolean",
      arguments: DocumentedFlag.booleans.filter { $0.environment.hasPrefix("SWOOP_") }
    )
    internal func legacyBooleanVariable(_ flag: DocumentedFlag) async throws {
      let legacy = "BUSHEL_" + flag.environment.dropFirst("SWOOP_".count)
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command],
        env: [legacy: "true"]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == "true")
    }

    @Test("BUSHEL_SYNC_DRY_RUN still makes a dry run, and SWOOP_SYNC_DRY_RUN wins")
    internal func legacyDryRun() async throws {
      let legacyOnly = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync"],
        env: ["BUSHEL_SYNC_DRY_RUN": "true"]
      )
      let both = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync"],
        env: ["BUSHEL_SYNC_DRY_RUN": "true", "SWOOP_SYNC_DRY_RUN": "false"]
      )

      #expect(try await legacyOnly.loadConfiguration().sync?.dryRun == true)
      #expect(try await both.loadConfiguration().sync?.dryRun == false)
    }

    @Test("BUSHEL_FETCH_INTERVAL_GLOBAL still sets the global interval")
    internal func legacyFetchInterval() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync"],
        env: ["BUSHEL_FETCH_INTERVAL_GLOBAL": "900"]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.fetch?.globalMinimumFetchInterval == 900)
    }

    @Test("--dry-run wins over SWOOP_SYNC_DRY_RUN=false")
    internal func flagWinsOverVariable() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync", "--dry-run"],
        env: ["SWOOP_SYNC_DRY_RUN": "false"]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == true)
    }
  }
}
