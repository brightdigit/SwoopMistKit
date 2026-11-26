//
//  SimulatorRuntimeIssue.swift
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

/// A downloadable in Apple's simulator index that couldn't become a runtime record.
///
/// The builder never guesses: a name it can't parse, an unknown platform, or two
/// entries for one build that disagree are reported here and the build is skipped.
public struct SimulatorRuntimeIssue: Error, Sendable, Equatable, CustomStringConvertible {
  /// Why the downloadable was skipped.
  public enum Reason: Error, Sendable, Equatable {
    /// The `platform` identifier isn't one of the four simulator platforms.
    case unknownPlatform(String)
    /// The `name` isn't "<OS> <version>[ beta[ N]| Release Candidate[ N]] Simulator[ Runtime]".
    case unparsableName
    /// An unnumbered beta whose downloadable version has no beta number.
    case missingBetaNumber
    /// The name's OS doesn't match the `platform` identifier.
    case platformMismatch(String)
    /// Another entry for the same platform + build has a different label or version.
    case conflictingEntries
  }

  /// The runtime build.
  public let buildNumber: String
  /// The downloadable's name.
  public let name: String
  /// Why it was skipped.
  public let reason: Reason

  public var description: String {
    "\(buildNumber) \"\(name)\": \(reason)"
  }

  public init(buildNumber: String, name: String, reason: Reason) {
    self.buildNumber = buildNumber
    self.name = name
    self.reason = reason
  }
}
