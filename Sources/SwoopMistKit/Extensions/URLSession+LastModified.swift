//
//  URLSession+LastModified.swift
//  SwoopMistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

extension URLSession {
  /// Fetches the Last-Modified header from a URL using a HEAD request
  ///
  /// - Parameter url: The URL to fetch the header from
  /// - Returns: The Last-Modified date, or nil if not available or on error
  internal func fetchLastModified(from url: URL) async -> Date? {
    do {
      var request = URLRequest(url: url)
      request.httpMethod = "HEAD"

      let (_, response) = try await data(for: request)

      guard let httpResponse = response as? HTTPURLResponse,
        let lastModifiedString = httpResponse.value(forHTTPHeaderField: "Last-Modified")
      else {
        return nil
      }

      return Date(rfc2822String: lastModifiedString)
    } catch {
      return nil
    }
  }
}
