//
//  MockAPIRouter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
import UIKit

/// Turns a `URLRequest` into the bytes a server would have sent.
///
/// Slices the fixture at request time rather than shipping one file per page, so a
/// service's next-page call and the real pagination maths are genuinely exercised
/// instead of being replaced by file loading.
nonisolated struct MockAPIRouter: Sendable {
  /// What the mock should pretend is happening, so the error and empty states can be
  /// demonstrated without editing any feature code.
  enum FailureMode: Sendable {
    /// Answer normally from the fixture.
    case none
    /// Every request fails with a 500.
    case serverError
    /// Every request succeeds with zero rows.
    case empty
  }

  struct Configuration: Sendable {
    var latency: Duration
    var failureMode: FailureMode

    init(
      latency: Duration = .milliseconds(400),
      failureMode: FailureMode = .none
    ) {
      self.latency = latency
      self.failureMode = failureMode
    }
  }

  enum RouterError: Error {
    case missingFixture(String)
    case malformedFixture(String)
  }

  let configuration: Configuration
  private let bundle: Bundle

  init(
    configuration: Configuration = .init(),
    bundle: Bundle = .main
  ) {
    self.configuration = configuration
    self.bundle = bundle
  }
}

// MARK: - Methods

nonisolated extension MockAPIRouter {
  func response(for request: URLRequest) throws -> (status: Int, body: Data, contentType: String) {
    guard
      let url = request.url,
      let endpoint = MockEndpoint.match(path: url.path, method: request.httpMethod ?? "GET")
    else {
      let path = request.url?.path ?? "-"
      let body = try envelope(status: 404, message: "No mock registered for \(path)", data: nil, meta: nil)

      return (404, body, "application/json")
    }

    if case let .image(seed) = endpoint {
      return (200, imageData(seed: seed), endpoint.contentType)
    }

    switch configuration.failureMode {
    case .serverError:
      let body = try envelope(status: 500, message: "Mocked server error", data: nil, meta: nil)
      return (500, body, endpoint.contentType)

    case .empty:
      // "No rows" for a request that addresses one resource means that resource is not
      // there. An empty array would hand the caller something it cannot decode.
      if let rowID = endpoint.fixtureRowID {
        let body = try envelope(status: 404, message: "No recipe with id \(rowID)", data: nil, meta: nil)
        return (404, body, endpoint.contentType)
      }

      let perPage = intQuery("per_page", from: url) ?? 10
      let body = try envelope(
        status: 200,
        message: "OK",
        data: [],
        meta: meta(total: 0, perPage: perPage, currentPage: 1, sliceCount: 0)
      )

      return (200, body, endpoint.contentType)

    case .none:
      break
    }

    guard let fixtureName = endpoint.fixtureName else {
      throw RouterError.missingFixture(String(describing: endpoint))
    }

    let rows = try fixtureRows(named: fixtureName)

    // A detail endpoint: one row out of the collection fixture, enveloped as an object
    // rather than an array. An id nothing matches is a 404, exactly as a real backend
    // would answer it.
    if let rowID = endpoint.fixtureRowID {
      guard let row = rows.first(where: { $0["id"] as? String == rowID }) else {
        let body = try envelope(status: 404, message: "No recipe with id \(rowID)", data: nil, meta: nil)
        return (404, body, endpoint.contentType)
      }

      return try (200, envelope(status: 200, message: "OK", data: row, meta: nil), endpoint.contentType)
    }

    guard endpoint.isPaginated else {
      return try (200, envelope(status: 200, message: "OK", data: rows, meta: nil), endpoint.contentType)
    }

    let page = intQuery("page", from: url) ?? 1
    let perPage = intQuery("per_page", from: url) ?? 10
    let slice = paginate(rows, page: page, perPage: perPage)

    let body = try envelope(
      status: 200,
      message: "OK",
      data: slice,
      meta: meta(total: rows.count, perPage: perPage, currentPage: page, sliceCount: slice.count)
    )

    return (200, body, endpoint.contentType)
  }
}

// MARK: - Images

private nonisolated extension MockAPIRouter {
  /// A flat tile whose hue is derived from the filename, so a given recipe always gets
  /// the same colour. Generated rather than bundled — 24 photographs would add megabytes
  /// to the repository for a demo that only needs something in the image slot.
  func imageData(seed: String) -> Data {
    let size = CGSize(width: 600, height: 400)
    let hue = CGFloat(Self.stableHash(seed) % 360) / 360

    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.pngData { context in
      UIColor(hue: hue, saturation: 0.45, brightness: 0.75, alpha: 1).setFill()
      context.fill(CGRect(origin: .zero, size: size))

      UIColor(hue: hue, saturation: 0.55, brightness: 0.60, alpha: 1).setFill()
      context.fill(CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.height * 0.38))
    }
  }

  /// `hashValue` is seeded per process, so it would give a recipe a different colour on
  /// every launch. This one does not.
  static func stableHash(_ value: String) -> Int {
    value.unicodeScalars.reduce(into: 7) { partial, scalar in
      partial = (partial &* 31 &+ Int(scalar.value)) & 0x00FF_FFFF
    }
  }
}

// MARK: - Fixtures

private nonisolated extension MockAPIRouter {
  func fixtureRows(named name: String) throws -> [[String: Any]] {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
      throw RouterError.missingFixture(name)
    }

    let data = try Data(contentsOf: url)

    guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
      throw RouterError.malformedFixture(name)
    }

    return rows
  }
}

// MARK: - Pagination

private nonisolated extension MockAPIRouter {
  /// Pages are 1-based, matching `Page`. A page past the end is an empty page rather than
  /// an error — which is what a real paginated API does.
  func paginate(
    _ rows: [[String: Any]],
    page: Int,
    perPage: Int
  ) -> [[String: Any]] {
    guard page >= 1, perPage >= 1 else { return [] }

    let start = (page - 1) * perPage
    guard start < rows.count else { return [] }

    let end = min(start + perPage, rows.count)

    return Array(rows[start ..< end])
  }

  func meta(
    total: Int,
    perPage: Int,
    currentPage: Int,
    sliceCount: Int
  ) -> [String: Any] {
    let lastPage = total == 0 ? 1 : Int(ceil(Double(total) / Double(perPage)))

    return [
      "total": total,
      "per_page": perPage,
      "current_page": currentPage,
      "last_page": lastPage,
      "from": sliceCount == 0 ? NSNull() : (currentPage - 1) * perPage + 1,
      "to": sliceCount == 0 ? NSNull() : (currentPage - 1) * perPage + sliceCount,
    ]
  }
}

// MARK: - Envelope

private nonisolated extension MockAPIRouter {
  /// Matches the shape `APIResponse` decodes: `http_status`, `message`, `data`, `meta`.
  func envelope(
    status: Int,
    message: String,
    data: Any?,
    meta: [String: Any]?
  ) throws -> Data {
    var root: [String: Any] = [
      "http_status": status,
      "message": message,
      "data": data ?? NSNull(),
    ]

    if let meta {
      root["meta"] = meta
    }

    return try JSONSerialization.data(withJSONObject: root)
  }

  func intQuery(_ name: String, from url: URL) -> Int? {
    URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first { $0.name == name }?
      .value
      .flatMap(Int.init)
  }
}
