//
//  ExportConfiguration.swift
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

/// Export command configuration
public struct ExportConfiguration: Sendable {
  public var output: String?
  public var pretty: Bool
  public var signedOnly: Bool
  public var noBetas: Bool
  public var verbose: Bool
  /// Where `--snapshot` writes a `ReleaseDataSnapshot`; `nil` for the generic export.
  public var snapshot: String?
  /// Whether `--snapshot` may read Production (`--allow-production`).
  public var allowProduction: Bool

  public init(
    output: String? = nil,
    pretty: Bool = false,
    signedOnly: Bool = false,
    noBetas: Bool = false,
    verbose: Bool = false,
    snapshot: String? = nil,
    allowProduction: Bool = false
  ) {
    self.output = output
    self.pretty = pretty
    self.signedOnly = signedOnly
    self.noBetas = noBetas
    self.verbose = verbose
    self.snapshot = snapshot
    self.allowProduction = allowProduction
  }
}
