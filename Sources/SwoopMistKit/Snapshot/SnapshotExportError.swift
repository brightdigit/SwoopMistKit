//
//  SnapshotExportError.swift
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

/// Why ``ReleaseDataSnapshotExport`` stopped.
///
/// No case carries a credential.
public enum SnapshotExportError: Error, Sendable, CustomStringConvertible {
  /// The environment is Production and `--allow-production` wasn't passed.
  case productionNotAllowed
  /// `--snapshot` was combined with an option that only applies to the generic export.
  case conflictingOptions([String])
  /// A CloudKit query failed.
  case query(recordType: String, message: String)
  /// A record type has no records, so the snapshot would be incomplete.
  case noRecords(recordType: String)
  /// Records that didn't map to their SwoopKit type.
  case unmappedRecords(recordType: String, recordNames: [String])
  /// The snapshot couldn't be encoded, read back or written.
  case output(String)

  /// A one-line explanation for the command line.
  public var description: String {
    switch self {
    case .productionNotAllowed:
      "CLOUDKIT_ENVIRONMENT is production. The snapshot export reads Development "
        + "unless --allow-production is passed."
    case .conflictingOptions(let flags):
      "--snapshot can't be combined with \(flags.joined(separator: ", "))."
    case .query(let recordType, let message):
      "Querying \(recordType) failed: \(message)"
    case .noRecords(let recordType):
      "CloudKit returned no \(recordType) records."
    case .unmappedRecords(let recordType, let recordNames):
      "\(recordNames.count) \(recordType) records didn't map: "
        + recordNames.joined(separator: ", ")
    case .output(let message):
      "Writing the snapshot failed: \(message)"
    }
  }
}
