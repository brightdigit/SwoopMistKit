//
//  ConfigurationLoader.swift
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

internal import ConfigKeyKit
internal import Configuration
internal import Foundation

/// Actor responsible for loading configuration from CLI arguments and environment variables
///
/// Each key is looked up in its own source: its flag (`--dry-run`) only on the
/// command line, and its variable (`SWOOP_SYNC_DRY_RUN`) only in the environment.
/// A shared reader would also look a flag up as an environment variable
/// (`--verbose` as `VERBOSE`).
public actor ConfigurationLoader {
  private let commandLineReader: ConfigReader
  private let environmentReader: ConfigReader
  /// The environment, with `BUSHEL_*` names copied to `SWOOP_*`.
  internal let environment: [String: String]

  /// Initialize the configuration loader with the process's arguments and environment
  public init() {
    self.init(
      arguments: CommandLine.arguments,
      environment: ProcessInfo.processInfo.environment
    )
  }

  /// Initialize the configuration loader with explicit arguments and environment
  ///
  /// - Parameters:
  ///   - arguments: The command line, starting with the program name
  ///     (`["swoopmist", "sync", "--dry-run"]`).
  ///   - environment: The environment variables. Old `BUSHEL_*` names are
  ///     copied to their `SWOOP_*` names, with a warning.
  internal init(arguments: [String], environment: [String: String]) {
    // Priority 1: command-line arguments (`--key value`, `--key=value` and bare `--flag`).
    self.commandLineReader = ConfigReader(
      provider: CommandLineArgumentsProvider(
        arguments: arguments,
        secretsSpecifier: .specific([
          "--cloudkit-key-id",
          "--cloudkit-private-key-path",
          "--cloudkit-private-key",
          "--virtualbuddy-api-key",
        ])
      )
    )

    // Priority 2: Environment variables. Old BUSHEL_* names still work,
    // with a warning, until they're removed.
    let migration = LegacyEnvironment.migrating(environment)
    for (legacy, current) in migration.renamed {
      FileHandle.standardError.write(
        Data("warning: \(legacy) is deprecated; use \(current) instead.\n".utf8)
      )
    }
    self.environment = migration.environment
    self.environmentReader = ConfigReader(
      provider: EnvironmentVariablesProvider(environmentVariables: migration.environment)
    )
  }

  // MARK: - Helper Methods

  /// Read a string value from one source
  ///
  /// On the command line a value arrives split on commas, so the parts are
  /// joined again; an option with no value (a bare `--output`) is absent.
  internal func readString(forKey key: String, from source: ConfigKeySource) -> String? {
    switch source {
    case .commandLine:
      guard let values = commandLineReader.stringArray(forKey: ConfigKey(key)), !values.isEmpty
      else {
        return nil
      }
      return values.joined(separator: ",")
    case .environment:
      return environmentReader.string(forKey: ConfigKey(key))
    }
  }

  /// Read an integer value from one source
  internal func readInt(forKey key: String, from source: ConfigKeySource) -> Int? {
    readString(forKey: key, from: source).flatMap { Int($0) }
  }

  /// Read a double value from one source
  internal func readDouble(forKey key: String, from source: ConfigKeySource) -> Double? {
    readString(forKey: key, from: source).flatMap { Double($0) }
  }

  // MARK: - Generic Helper Methods for ConfigKey (with defaults)

  /// Read a string value with automatic CLI → ENV → default fallback
  /// Returns non-optional since ConfigKey has a required default
  internal func read(_ key: ConfigKeyKit.ConfigKey<String>) -> String {
    for source in ConfigKeySource.priority {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readString(forKey: keyString, from: source) {
        return value
      }
    }
    return key.defaultValue  // Non-optional!
  }

  /// Read a boolean value with enhanced ENV variable parsing
  ///
  /// Returns non-optional since ConfigKey has a required default.
  ///
  /// Boolean parsing rules:
  /// - CLI: Flag presence indicates true (e.g., `--verbose`). Only an explicit
  ///   `--verbose=false` (or `0`, `no`) is false.
  /// - ENV: Accepts "true", "1", "yes" (case-insensitive)
  /// - Empty string in ENV is treated as absent (falls back to default)
  ///
  /// - Parameter key: Configuration key with boolean type
  /// - Returns: Boolean value from CLI/ENV or the key's default
  internal func read(_ key: ConfigKeyKit.ConfigKey<Bool>) -> Bool {
    // Try CLI first (presence-based for flags)
    if let cliKey = key.key(for: .commandLine),
      let values = commandLineReader.stringArray(forKey: ConfigKey(cliKey))
    {
      guard values.count == 1, let value = values.first else {
        return true
      }
      let lowercased = value.lowercased().trimmingCharacters(in: .whitespaces)
      return !["false", "0", "no"].contains(lowercased)
    }

    // Try ENV (may have string value like VERBOSE=true)
    if let envKey = key.key(for: .environment),
      let envValue = readString(forKey: envKey, from: .environment)
    {
      let lowercased = envValue.lowercased().trimmingCharacters(in: .whitespaces)
      return lowercased == "true" || lowercased == "1" || lowercased == "yes"
    }

    // Use default value (non-optional)
    return key.defaultValue
  }

  // MARK: - Generic Helper Methods for OptionalConfigKey (without defaults)

  /// Read a string value with automatic CLI → ENV fallback
  /// Returns optional since OptionalConfigKey has no default
  internal func read(_ key: ConfigKeyKit.OptionalConfigKey<String>) -> String? {
    for source in ConfigKeySource.priority {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readString(forKey: keyString, from: source) {
        return value
      }
    }
    return nil  // No default available
  }

  /// Read an integer value with automatic CLI → ENV fallback
  /// Returns optional since OptionalConfigKey has no default
  internal func read(_ key: ConfigKeyKit.OptionalConfigKey<Int>) -> Int? {
    for source in ConfigKeySource.priority {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readInt(forKey: keyString, from: source) {
        return value
      }
    }
    return nil  // No default available
  }

  /// Read a double value with automatic CLI → ENV fallback
  /// Returns optional since OptionalConfigKey has no default
  internal func read(_ key: ConfigKeyKit.OptionalConfigKey<Double>) -> Double? {
    for source in ConfigKeySource.priority {
      guard let keyString = key.key(for: source) else { continue }
      if let value = readDouble(forKey: keyString, from: source) {
        return value
      }
    }
    return nil  // No default available
  }
}
