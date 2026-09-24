//
//  MockAPIRouter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Turns a `URLRequest` into the bytes a server would have sent.
///
/// Filters and slices the fixture at request time rather than shipping one file per page
/// and per facet, so a service's next-page call, the real pagination maths and every
/// filter the app can send are genuinely exercised instead of replaced by file loading.
///
/// The filtering runs before the slice, which is what makes `meta.total` report matches
/// rather than the size of the collection.
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

  /// What a request resolved to — everything the transport needs to build an
  /// `HTTPURLResponse` and hand back a body.
  struct Response: Sendable {
    let status: Int
    let body: Data
    let contentType: String
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
  func response(for request: URLRequest) throws -> Response {
    guard
      let url = request.url,
      let endpoint = MockEndpoint.match(path: url.path, method: request.httpMethod ?? "GET")
    else {
      return try unroutedResponse(path: request.url?.path ?? "-")
    }

    if let forced = try forcedResponse(for: endpoint, url: url) {
      return forced
    }

    return try fixtureResponse(for: endpoint, url: url)
  }
}

// MARK: - Routing

private nonisolated extension MockAPIRouter {
  /// The response the configured failure mode demands, or `nil` when the fixture should
  /// answer normally.
  func forcedResponse(for endpoint: MockEndpoint, url: URL) throws -> Response? {
    switch configuration.failureMode {
    case .serverError:
      try serverErrorResponse(contentType: endpoint.contentType)

    case .empty:
      try emptyResponse(for: endpoint, url: url)

    case .none:
      nil
    }
  }

  func fixtureResponse(for endpoint: MockEndpoint, url: URL) throws -> Response {
    guard let fixtureName = endpoint.fixtureName else {
      throw RouterError.missingFixture(String(describing: endpoint))
    }

    let all = try fixtureRows(named: fixtureName)
    let rows = endpoint.isFilterable ? filtered(all, for: url) : all

    if let rowID = endpoint.fixtureRowID {
      return try detailResponse(
        rowID: rowID,
        in: rows,
        contentType: endpoint.contentType
      )
    }

    guard endpoint.isPaginated else {
      return try collectionResponse(rows: rows, contentType: endpoint.contentType)
    }

    return try pageResponse(
      rows: rows,
      url: url,
      contentType: endpoint.contentType
    )
  }
}

// MARK: - Responses

private nonisolated extension MockAPIRouter {
  func unroutedResponse(path: String) throws -> Response {
    let body = try envelope(
      status: 404,
      message: "No mock registered for \(path)",
      data: nil,
      meta: nil
    )

    return Response(
      status: 404,
      body: body,
      contentType: "application/json"
    )
  }

  func serverErrorResponse(contentType: String) throws -> Response {
    let body = try envelope(
      status: 500,
      message: "Mocked server error",
      data: nil,
      meta: nil
    )

    return Response(
      status: 500,
      body: body,
      contentType: contentType
    )
  }

  /// "No rows" for a request that addresses one resource means that resource is not
  /// there. An empty array would hand the caller something it cannot decode.
  func emptyResponse(for endpoint: MockEndpoint, url: URL) throws -> Response {
    if let rowID = endpoint.fixtureRowID {
      return try missingRowResponse(rowID: rowID, contentType: endpoint.contentType)
    }

    let perPage = intQuery("per_page", from: url) ?? 10
    let body = try envelope(
      status: 200,
      message: "OK",
      data: [],
      meta: meta(
        total: 0,
        perPage: perPage,
        currentPage: 1,
        sliceCount: 0
      )
    )

    return Response(
      status: 200,
      body: body,
      contentType: endpoint.contentType
    )
  }

  /// One row out of the collection fixture, enveloped as an object rather than an array.
  /// An id nothing matches is a 404, exactly as a real backend would answer it.
  func detailResponse(rowID: String, in rows: [[String: Any]], contentType: String) throws -> Response {
    guard let row = rows.first(where: { $0["id"] as? String == rowID }) else {
      return try missingRowResponse(rowID: rowID, contentType: contentType)
    }

    let body = try envelope(
      status: 200,
      message: "OK",
      data: row,
      meta: nil
    )

    return Response(
      status: 200,
      body: body,
      contentType: contentType
    )
  }

  func collectionResponse(rows: [[String: Any]], contentType: String) throws -> Response {
    let body = try envelope(
      status: 200,
      message: "OK",
      data: rows,
      meta: nil
    )

    return Response(
      status: 200,
      body: body,
      contentType: contentType
    )
  }

  func pageResponse(rows: [[String: Any]], url: URL, contentType: String) throws -> Response {
    let page = intQuery("page", from: url) ?? 1
    let perPage = intQuery("per_page", from: url) ?? 10
    let slice = paginate(
      rows,
      page: page,
      perPage: perPage
    )

    let body = try envelope(
      status: 200,
      message: "OK",
      data: slice,
      meta: meta(
        total: rows.count,
        perPage: perPage,
        currentPage: page,
        sliceCount: slice.count
      )
    )

    return Response(
      status: 200,
      body: body,
      contentType: contentType
    )
  }

  func missingRowResponse(rowID: String, contentType: String) throws -> Response {
    let body = try envelope(
      status: 404,
      message: "No recipe with id \(rowID)",
      data: nil,
      meta: nil
    )

    return Response(
      status: 404,
      body: body,
      contentType: contentType
    )
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

  func filtered(_ rows: [[String: Any]], for url: URL) -> [[String: Any]] {
    let filter = MockRecipeFilter(url: url)

    return rows.filter(filter.matches)
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
