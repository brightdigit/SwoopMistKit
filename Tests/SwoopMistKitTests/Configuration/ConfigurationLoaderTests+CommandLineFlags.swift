//
//  ConfigurationLoaderTests+CommandLineFlags.swift
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
  /// The flags the README and DocC articles document, parsed the way the
  /// `swoopmist` executable parses them.
  ///
  /// 1.0.0-alpha.2 read `sync.dry_run` as `--sync-dry_run`, so a documented
  /// `swoopmist sync --dry-run` wrote to CloudKit.
  @Suite("Command-Line Flags")
  internal struct CommandLineFlags {
    // MARK: - Regression

    @Test("sync --dry-run is a dry run")
    internal func syncDryRun() async throws {
      let loader = ConfigurationLoaderTests.createLoader(cliArgs: ["sync", "--dry-run"], env: [:])

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == true)
    }

    @Test("sync --dry-run --verbose sets both")
    internal func syncDryRunVerbose() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync", "--dry-run", "--verbose"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == true)
      #expect(config.sync?.verbose == true)
    }

    @Test("export --output data.json --pretty sets both")
    internal func exportOutputPretty() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["export", "--output", "data.json", "--pretty"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.export?.output == "data.json")
      #expect(config.export?.pretty == true)
    }

    // MARK: - Boolean Flags

    @Test("A documented boolean flag sets its value", arguments: DocumentedFlag.booleans)
    internal func booleanFlagIsTrue(_ flag: DocumentedFlag) async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command, flag.flag],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == "true")
    }

    @Test("A boolean flag is false without the flag", arguments: DocumentedFlag.booleans)
    internal func booleanFlagDefault(_ flag: DocumentedFlag) async throws {
      let loader = ConfigurationLoaderTests.createLoader(cliArgs: [flag.command], env: [:])

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == "false")
    }

    @Test("--flag=false is false", arguments: DocumentedFlag.booleans)
    internal func booleanFlagExplicitFalse(_ flag: DocumentedFlag) async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command, "\(flag.flag)=false"],
        env: [flag.environment: "true"]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == "false")
    }

    @Test("A stray argument after --dry-run keeps the dry run")
    internal func strayArgumentAfterFlag() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync", "--dry-run", "extra"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == true)
    }

    // MARK: - Options with Values

    @Test("A documented option sets its value", arguments: DocumentedFlag.options)
    internal func optionValue(_ flag: DocumentedFlag) async throws {
      let value = try #require(flag.value)
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command, flag.flag, value],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == value)
    }

    @Test("A documented option accepts --option=value", arguments: DocumentedFlag.options)
    internal func optionEqualsValue(_ flag: DocumentedFlag) async throws {
      let value = try #require(flag.value)
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: [flag.command, "\(flag.flag)=\(value)"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == value)
    }

    @Test("An option is unset without the option", arguments: DocumentedFlag.options)
    internal func optionDefault(_ flag: DocumentedFlag) async throws {
      let loader = ConfigurationLoaderTests.createLoader(cliArgs: [flag.command], env: [:])

      let config = try await loader.loadConfiguration()

      #expect(flag.read(config) == nil)
    }

    @Test("A value with a comma survives the command line")
    internal func optionValueWithComma() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["export", "--output", "a,b.json"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.export?.output == "a,b.json")
    }

    @Test("--cloudkit-container-id and --cloudkit-environment replace their defaults")
    internal func cloudKitOptionsWithDefaults() async throws {
      let withFlags = ConfigurationLoaderTests.createLoader(
        cliArgs: [
          "sync",
          "--cloudkit-container-id", "iCloud.com.example.App",
          "--cloudkit-environment", "production",
        ],
        env: [:]
      )
      let withoutFlags = ConfigurationLoaderTests.createLoader(cliArgs: ["sync"], env: [:])

      let flags = try await withFlags.loadConfiguration()
      let defaults = try await withoutFlags.loadConfiguration()

      #expect(flags.cloudKit?.containerID == "iCloud.com.example.App")
      #expect(flags.cloudKit?.environment == "production")
      #expect(defaults.cloudKit?.containerID == "iCloud.com.brightdigit.Swoop")
      #expect(defaults.cloudKit?.environment == "development")
    }

    // MARK: - Isolation

    @Test("A flag isn't read from an environment variable of the same name")
    internal func flagsIgnoreBareEnvironmentNames() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync"],
        env: ["DRY_RUN": "true", "VERBOSE": "1", "SOURCE": "ipsw.me", "OUTPUT": "x.json"]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == false)
      #expect(config.sync?.verbose == false)
      #expect(config.sync?.source == nil)
      #expect(config.export?.output == nil)
    }

    @Test("The old dot-separated key is not a flag")
    internal func dotSeparatedKeyIsNotAFlag() async throws {
      let loader = ConfigurationLoaderTests.createLoader(
        cliArgs: ["sync", "--sync-dry_run", "--sync.dry_run"],
        env: [:]
      )

      let config = try await loader.loadConfiguration()

      #expect(config.sync?.dryRun == false)
    }
  }
}
