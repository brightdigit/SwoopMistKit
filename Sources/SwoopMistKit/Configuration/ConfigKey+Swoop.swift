//
//  ConfigKey+Swoop.swift
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

public import ConfigKeyKit

// MARK: - SwoopMistKit-Specific Config Key Helpers

/// The environment-variable prefixes for SwoopMistKit's own keys.
public enum ConfigKeyPrefix {
  /// The prefix every key uses: `SWOOP_SYNC_DRY_RUN`, for example.
  public static let current = "SWOOP"
  /// The prefix from before the rename (`BUSHEL_SYNC_DRY_RUN`), still read
  /// with a deprecation warning. See ``ConfigurationLoader``.
  public static let legacy = "BUSHEL"

  /// The `SWOOP_` environment variable for a base key: `sync.dry_run` → `SWOOP_SYNC_DRY_RUN`.
  internal static func environmentName(for base: String) -> String {
    StandardNamingStyle.screamingSnakeCase(prefix: current).transform(base)
  }
}

extension ConfigKey {
  /// Convenience initializer for keys with `SWOOP_` environment-variable prefix.
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.dry_run")
  ///   - defaultVal: Required default value
  public init(swoopPrefixed base: String, default defaultVal: Value) {
    self.init(base, envPrefix: ConfigKeyPrefix.current, default: defaultVal)
  }
}

extension ConfigKey where Value == Bool {
  /// Convenience initializer for boolean keys with `SWOOP_` environment-variable prefix.
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - defaultVal: Default value (defaults to false)
  public init(swoopPrefixed base: String, default defaultVal: Bool = false) {
    self.init(base, envPrefix: ConfigKeyPrefix.current, default: defaultVal)
  }
}

extension ConfigKey where Value == Bool {
  /// A boolean key read from the `--<cli>` flag and the `SWOOP_` environment variable.
  ///
  /// `ConfigKey<Bool>(swoopPrefixed: "sync.dry_run", cli: "dry-run")` reads
  /// `--dry-run` and `SWOOP_SYNC_DRY_RUN`.
  /// - Parameters:
  ///   - base: Base key string; the environment variable is built from it.
  ///   - cli: The flag name without the leading `--`, in kebab-case.
  ///   - defaultVal: Default value (defaults to false)
  internal init(swoopPrefixed base: String, cli: String, default defaultVal: Bool = false) {
    self.init(cli: cli, env: ConfigKeyPrefix.environmentName(for: base), default: defaultVal)
  }
}

extension OptionalConfigKey {
  /// Convenience initializer for optional keys with `SWOOP_` environment-variable prefix.
  /// - Parameter base: Base key string (e.g., "sync.min_interval")
  public init(swoopPrefixed base: String) {
    self.init(base, envPrefix: ConfigKeyPrefix.current)
  }

  /// An optional key read from the `--<cli>` option and the `SWOOP_` environment variable.
  ///
  /// `OptionalConfigKey<String>(swoopPrefixed: "export.output", cli: "output")` reads
  /// `--output` and `SWOOP_EXPORT_OUTPUT`.
  /// - Parameters:
  ///   - base: Base key string; the environment variable is built from it.
  ///   - cli: The option name without the leading `--`, in kebab-case.
  internal init(swoopPrefixed base: String, cli: String) {
    self.init(cli: cli, env: ConfigKeyPrefix.environmentName(for: base))
  }
}
