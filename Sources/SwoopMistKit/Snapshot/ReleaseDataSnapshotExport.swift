//
//  ReleaseDataSnapshotExport.swift
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
public import MistKit
public import SwoopKit

/// Exports `SDKVersion`, `XcodeVersion` and `SimulatorRuntime` from CloudKit
/// as SwoopKit's `ReleaseDataSnapshot`: an app's bundled snapshot
/// (`swoopmist export --snapshot <output.json>`).
///
/// Read-only: it only queries, through `queryAllRecords`, which pages past
/// CloudKit's 200-record limit. Every record maps with its
/// `from(recordInfo:)`, so the fields are the ones `sync` writes; the export
/// fails if a type has no records or any record doesn't map. Records are
/// sorted by record name so the file diffs well, `fetchedAt` is whole
/// seconds, and the JSON is SwoopKit's
/// `JSONEncoder.iso8601PrettySorted` plus a trailing newline:
/// byte for byte what Stewed's `release-data-snapshot` tool wrote.
public enum ReleaseDataSnapshotExport {
  /// Queries the three record types and builds the snapshot.
  ///
  /// - Parameters:
  ///   - service: The CloudKit client; only `queryAllRecords` is called.
  ///   - fetchedAt: When the export ran; it's truncated to whole seconds.
  /// - Returns: The snapshot, each type sorted by record name.
  /// - Throws: ``SnapshotExportError/query(recordType:message:)``,
  ///   ``SnapshotExportError/noRecords(recordType:)`` or
  ///   ``SnapshotExportError/unmappedRecords(recordType:recordNames:)``.
  public static func snapshot(
    from service: some RecordManaging,
    fetchedAt: Date = .now
  ) async throws(SnapshotExportError) -> ReleaseDataSnapshot {
    ReleaseDataSnapshot(
      fetchedAt: fetchedAt.wholeSeconds,
      sdkVersions: try await records(SDKVersionRecord.self, from: service),
      xcodeVersions: try await records(XcodeVersionRecord.self, from: service),
      simulatorRuntimes: try await records(SimulatorRuntimeRecord.self, from: service)
    )
  }

  /// Every record of `type`, in record-name order.
  ///
  /// - Throws: ``SnapshotExportError/noRecords(recordType:)`` when there are
  ///   none and ``SnapshotExportError/unmappedRecords(recordType:recordNames:)``
  ///   when any record doesn't map: a committed snapshot shouldn't silently
  ///   lose records.
  public static func records<Record: CloudKitRecord>(
    _ type: Record.Type,
    from service: some RecordManaging
  ) async throws(SnapshotExportError) -> [Record] {
    let recordType = Record.cloudKitRecordType
    let infos: [RecordInfo]
    do {
      infos = try await service.queryAllRecords(recordType: recordType)
    } catch {
      throw .query(recordType: recordType, message: error.localizedDescription)
    }
    return try records(Record.self, mapping: infos)
  }

  /// Maps `infos` to `Record`, sorted by record name.
  ///
  /// - Throws: ``SnapshotExportError/noRecords(recordType:)`` or
  ///   ``SnapshotExportError/unmappedRecords(recordType:recordNames:)``.
  internal static func records<Record: CloudKitRecord>(
    _ type: Record.Type,
    mapping infos: [RecordInfo]
  ) throws(SnapshotExportError) -> [Record] {
    let recordType = Record.cloudKitRecordType
    guard !infos.isEmpty else {
      throw .noRecords(recordType: recordType)
    }
    let sorted = infos.sorted { $0.recordName < $1.recordName }
    var mapped: [Record] = []
    var unmapped: [String] = []
    for info in sorted {
      if let record = Record.from(recordInfo: info) {
        mapped.append(record)
      } else {
        unmapped.append(info.recordName)
      }
    }
    guard unmapped.isEmpty else {
      throw .unmappedRecords(recordType: recordType, recordNames: unmapped)
    }
    return mapped
  }

  /// The snapshot's JSON: SwoopKit's encoder, then a newline, checked by
  /// decoding it back.
  ///
  /// - Throws: ``SnapshotExportError/output(_:)``.
  public static func encode(_ snapshot: ReleaseDataSnapshot) throws(SnapshotExportError) -> Data {
    do {
      var data = try JSONEncoder.iso8601PrettySorted.encode(snapshot)
      data.append(Data("\n".utf8))
      _ = try ReleaseDataSnapshot(json: data)
      return data
    } catch {
      throw .output(error.localizedDescription)
    }
  }

  /// Writes ``encode(_:)``'s JSON to `url` atomically.
  ///
  /// - Returns: The file's size in bytes.
  /// - Throws: ``SnapshotExportError/output(_:)``.
  @discardableResult
  public static func write(
    _ snapshot: ReleaseDataSnapshot,
    to url: URL
  ) throws(SnapshotExportError) -> Int {
    let data = try encode(snapshot)
    do {
      try data.write(to: url, options: .atomic)
    } catch {
      throw .output(error.localizedDescription)
    }
    return data.count
  }
}
