//
//  ReleaseDataSnapshotExportValidationTests.swift
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

internal import MistKit
internal import Testing

@testable import SwoopMistKit

@Suite("Release-Data Snapshot Export Validation")
internal struct ReleaseDataSnapshotExportValidationTests {
  @Test("Development is allowed by default")
  internal func developmentAllowed() throws {
    try ReleaseDataSnapshotExport.validate(
      ExportConfiguration(snapshot: "out.json"),
      environment: .development
    )
  }

  @Test("Production is refused without --allow-production")
  internal func productionRefused() {
    #expect(throws: SnapshotExportError.self) {
      try ReleaseDataSnapshotExport.validate(
        ExportConfiguration(snapshot: "out.json"),
        environment: .production
      )
    }
  }

  @Test("Production is allowed with --allow-production")
  internal func productionAllowedWithFlag() throws {
    try ReleaseDataSnapshotExport.validate(
      ExportConfiguration(snapshot: "out.json", allowProduction: true),
      environment: .production
    )
  }

  @Test("The generic export's options are refused with --snapshot")
  internal func conflictingOptions() {
    let configuration = ExportConfiguration(
      output: "data.json",
      pretty: true,
      signedOnly: true,
      noBetas: true,
      snapshot: "out.json"
    )

    #expect {
      try ReleaseDataSnapshotExport.validate(configuration, environment: .development)
    } throws: { error in
      guard case .conflictingOptions(let flags) = error as? SnapshotExportError else {
        return false
      }
      return flags == ["--output", "--pretty", "--signed-only", "--no-betas"]
    }
  }
}
