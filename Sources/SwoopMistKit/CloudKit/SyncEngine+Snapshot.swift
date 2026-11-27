//
//  SyncEngine+Snapshot.swift
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
public import SwoopKit

extension SyncEngine {
  /// Exports `SDKVersion`, `XcodeVersion` and `SimulatorRuntime` as a
  /// `ReleaseDataSnapshot`. Read-only.
  ///
  /// See ``ReleaseDataSnapshotExport/snapshot(from:fetchedAt:)``.
  ///
  /// - Parameter fetchedAt: When the export ran; truncated to whole seconds.
  /// - Returns: The snapshot, each type sorted by record name.
  /// - Throws: ``SnapshotExportError`` when a query fails, a type is empty or
  ///   a record doesn't map.
  public func exportSnapshot(
    fetchedAt: Date = .now
  ) async throws(SnapshotExportError) -> ReleaseDataSnapshot {
    try await ReleaseDataSnapshotExport.snapshot(from: cloudKitService, fetchedAt: fetchedAt)
  }
}
