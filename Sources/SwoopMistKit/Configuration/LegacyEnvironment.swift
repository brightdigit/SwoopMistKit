//
//  LegacyEnvironment.swift
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

/// Reads environment variables under the prefix from before the rename.
///
/// SwoopMistKit was BushelCloud, and its variables were `BUSHEL_*`. Each
/// `BUSHEL_X` with no `SWOOP_X` is copied to `SWOOP_X`, so old scripts and
/// CI keep working; a `SWOOP_X` that's set wins. The caller warns about
/// each copied name.
internal enum LegacyEnvironment {
  /// The environment with legacy names copied to current ones, and the
  /// `(legacy, current)` pairs that were copied, sorted by name.
  internal static func migrating(
    _ environment: [String: String]
  ) -> (environment: [String: String], renamed: [(String, String)]) {
    let legacyPrefix = ConfigKeyPrefix.legacy + "_"
    let currentPrefix = ConfigKeyPrefix.current + "_"
    var migrated = environment
    var renamed: [(String, String)] = []
    for (name, value) in environment where name.hasPrefix(legacyPrefix) {
      let current = currentPrefix + name.dropFirst(legacyPrefix.count)
      guard environment[current] == nil else {
        continue
      }
      migrated[current] = value
      renamed.append((name, current))
    }
    return (migrated, renamed.sorted { $0.0 < $1.0 })
  }
}
