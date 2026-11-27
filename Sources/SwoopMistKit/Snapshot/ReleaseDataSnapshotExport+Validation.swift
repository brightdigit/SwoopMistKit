//
//  ReleaseDataSnapshotExport+Validation.swift
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

public import MistKit

extension ReleaseDataSnapshotExport {
  /// Checks a snapshot export's options before anything is queried.
  ///
  /// Development is the default; Production needs `--allow-production`. The
  /// generic export's `--output`, `--pretty`, `--signed-only` and `--no-betas`
  /// don't apply to a snapshot, which is always complete and pretty-printed,
  /// so they're refused rather than ignored.
  ///
  /// - Parameters:
  ///   - configuration: The `export` options.
  ///   - environment: The CloudKit environment the export would read.
  /// - Throws: ``SnapshotExportError/conflictingOptions(_:)`` or
  ///   ``SnapshotExportError/productionNotAllowed``.
  public static func validate(
    _ configuration: ExportConfiguration,
    environment: MistKit.Environment
  ) throws(SnapshotExportError) {
    var conflicts: [String] = []
    if configuration.output != nil {
      conflicts.append("--output")
    }
    if configuration.pretty {
      conflicts.append("--pretty")
    }
    if configuration.signedOnly {
      conflicts.append("--signed-only")
    }
    if configuration.noBetas {
      conflicts.append("--no-betas")
    }
    guard conflicts.isEmpty else {
      throw .conflictingOptions(conflicts)
    }
    guard environment == .development || configuration.allowProduction else {
      throw .productionNotAllowed
    }
  }
}
