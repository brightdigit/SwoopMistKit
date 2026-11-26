//
//  LegacyEnvironmentTests.swift
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
internal import Testing

@testable import SwoopMistKit

/// `BUSHEL_*` variables still work after the rename to `SWOOP_*`.
@Suite("Legacy environment variables")
internal struct LegacyEnvironmentTests {
  @Test("A BUSHEL_ variable is copied to its SWOOP_ name and reported")
  internal func copiesLegacyNames() {
    let result = LegacyEnvironment.migrating([
      "BUSHEL_SYNC_DRY_RUN": "true",
      "CLOUDKIT_KEY_ID": "key",
    ])
    #expect(result.environment["SWOOP_SYNC_DRY_RUN"] == "true")
    #expect(result.environment["CLOUDKIT_KEY_ID"] == "key")
    #expect(result.renamed.map(\.0) == ["BUSHEL_SYNC_DRY_RUN"])
    #expect(result.renamed.map(\.1) == ["SWOOP_SYNC_DRY_RUN"])
  }

  @Test("A SWOOP_ variable wins over its BUSHEL_ name, with no warning")
  internal func currentNameWins() {
    let result = LegacyEnvironment.migrating([
      "BUSHEL_SYNC_VERBOSE": "true",
      "SWOOP_SYNC_VERBOSE": "false",
    ])
    #expect(result.environment["SWOOP_SYNC_VERBOSE"] == "false")
    #expect(result.renamed.isEmpty)
  }

  @Test("Keys use the SWOOP_ prefix")
  internal func keysUseTheCurrentPrefix() {
    #expect(ConfigurationKeys.Sync.dryRun.key(for: .environment) == "SWOOP_SYNC_DRY_RUN")
    #expect(
      ConfigurationKeys.Fetch.intervalGlobal.key(for: .environment)
        == "SWOOP_FETCH_INTERVAL_GLOBAL"
    )
    #expect(
      ConfigurationKeys.Fetch.intervalKey(for: "appledb.dev").key(for: .environment)
        == "SWOOP_FETCH_INTERVAL_APPLEDB_DEV"
    )
  }
}
