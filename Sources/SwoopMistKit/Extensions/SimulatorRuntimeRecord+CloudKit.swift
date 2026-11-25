//
//  SimulatorRuntimeRecord+CloudKit.swift
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

public import SwoopKit
internal import Foundation
public import MistKit

// MARK: - SDK builds field

extension SimulatorRuntimeRecord {
  /// The CloudKit field that holds `sdkBuildNumbers` as one comma-separated `STRING`.
  ///
  /// Workaround for brightdigit/MistKit#509: MistKit can't decode the `STRING_LIST`
  /// type tag in CloudKit responses, so any query or modify response that carried the
  /// old `sdkBuildNumbers` `LIST<STRING>` field failed the whole sync. CloudKit can't
  /// change a field's type, hence the new name. Build numbers never contain commas.
  ///
  /// TODO: Switch back to a `LIST<STRING>` field once MistKit#509 is fixed.
  public static let sdkBuildNumbersFieldName = "sdkBuildNumbersText"

  /// Joins SDK builds into the stored text, or `nil` when there are none
  /// (the field is left out, as the list field was).
  internal static func sdkBuildNumbersText(_ builds: [String]) -> String? {
    builds.isEmpty ? nil : builds.joined(separator: ",")
  }

  /// Splits the stored text back into SDK builds; a missing or empty value is `[]`.
  internal static func sdkBuildNumbers(fromText text: String?) -> [String] {
    guard let text else {
      return []
    }
    return text.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }
}

// MARK: - CloudKitRecord Conformance

extension SimulatorRuntimeRecord: @retroactive CloudKitRecord {
  public static var cloudKitRecordType: String { "SimulatorRuntime" }

  public static func from(recordInfo: RecordInfo) -> Self? {
    guard let platformString = recordInfo.fields["platform"]?.stringValue,
      let platform = Platform(rawValue: platformString),
      let version = recordInfo.fields["version"]?.stringValue,
      let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
      let labelText = recordInfo.fields["releaseLabel"]?.stringValue,
      let releaseLabel = ReleaseLabel(labelText)
    else {
      return nil
    }

    // MistKit#509 workaround: read the comma-separated STRING, not a list.
    let sdkBuildNumbers = Self.sdkBuildNumbers(
      fromText: recordInfo.fields[sdkBuildNumbersFieldName]?.stringValue
    )

    return SimulatorRuntimeRecord(
      platform: platform,
      version: version,
      buildNumber: buildNumber,
      releaseLabel: releaseLabel,
      sdkBuildNumbers: sdkBuildNumbers
    )
  }

  public static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let platform = recordInfo.fields["platform"]?.stringValue ?? "Unknown"
    let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
    let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
    let label = recordInfo.fields["releaseLabel"]?.stringValue ?? "Unknown"
    let sdkBuilds = Self.sdkBuildNumbers(
      fromText: recordInfo.fields[sdkBuildNumbersFieldName]?.stringValue
    )

    var output = "\n  \(platform) \(version) \(label) (Build \(build))\n"
    output += "    SDKs: \(sdkBuilds.isEmpty ? "none" : sdkBuilds.joined(separator: ", "))"
    return output
  }

  public func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "platform": .string(.value(platform.rawValue)),
      "version": .string(.value(version)),
      "buildNumber": .string(.value(buildNumber)),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
      "releaseLabel": .string(.value(releaseLabel.description)),
    ]

    // MistKit#509 workaround: one comma-separated STRING instead of a LIST<STRING>.
    // TODO: Write `.list(sdkBuildNumbers.map(FieldValue.string))` again once it's fixed.
    // Left out when empty, as the list field was.
    if let text = Self.sdkBuildNumbersText(sdkBuildNumbers) {
      fields[Self.sdkBuildNumbersFieldName] = .string(.value(text))
    }

    return fields
  }
}
