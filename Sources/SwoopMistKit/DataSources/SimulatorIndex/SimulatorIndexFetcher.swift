//
//  SimulatorIndexFetcher.swift
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

public import protocol BushelFoundation.DataSourceFetcher
internal import Foundation

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

/// Fetches simulator runtime builds from Apple's simulator index.
///
/// <https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex>
/// is public and needs no key, but it isn't a documented API. A failed fetch or decode
/// throws, so the sync stops before writing anything and existing records stay.
public struct SimulatorIndexFetcher: DataSourceFetcher, Sendable {
  public typealias Record = SimulatorRuntimeBuilder.Output

  // swiftlint:disable:next force_unwrapping
  internal static let indexURL = URL(
    string: "https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex"
  )!

  public init() {}

  /// Downloads and parses the index.
  ///
  /// - Returns: One record per platform + runtime build, plus the downloadables that
  ///   couldn't be parsed.
  public func fetch() async throws -> SimulatorRuntimeBuilder.Output {
    SimulatorRuntimeBuilder.build(from: try await fetchIndex())
  }

  /// Downloads and decodes the index without building records.
  ///
  /// - Returns: The decoded index, including its SDK mappings.
  public func fetchIndex() async throws -> SimulatorIndex {
    let (data, _) = try await URLSession.shared.data(from: Self.indexURL)
    return try SimulatorIndex(propertyList: data)
  }
}
