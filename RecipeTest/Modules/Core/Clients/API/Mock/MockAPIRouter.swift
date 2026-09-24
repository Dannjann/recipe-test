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

    let all = try fixtureRows(named: fixtureName)
    let rows = endpoint.isFilterable ? filtered(all, for: url) : all

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

// MARK: - Filtering

/// The query parameters the recipe collection can be narrowed by.
///
/// Parsed once per request so the filters below read as predicates rather than as
/// repeated query-string digging.
private nonisolated struct RecipeFilters {
  let category: String?
  let cuisine: String?
  let isVegetarian: Bool?
  let servings: String?
  let includedIngredients: [String]
  let excludedIngredients: [String]
  let searchText: String?
  let searchesSteps: Bool

  init(url: URL) {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    func values(_ name: String) -> [String] {
      items.filter { $0.name == name }.compactMap(\.value).filter { !$0.isEmpty }
    }

    category = values("category").first
    cuisine = values("cuisine").first
    isVegetarian = values("is_vegetarian").first.flatMap(Self.flag)
    servings = values("servings").first
    includedIngredients = values("include_ingredients")
    excludedIngredients = values("exclude_ingredients")
    searchText = values("search_text").first
    searchesSteps = values("searches_steps").first.flatMap(Self.flag) ?? false
  }

  /// Accepts both spellings a URL encoder might produce, and returns nil for anything
  /// else — an unrecognised *value* must be ignored like an unrecognised parameter, not
  /// silently become a filter for the opposite rows.
  private static func flag(_ value: String) -> Bool? {
    switch value.lowercased() {
    case "true", "1":
      true

    case "false", "0":
      false

    default:
      nil
    }
  }
}

private nonisolated extension MockAPIRouter {
  /// The prototype's serving filter offers 1, 2, 4 and "6+"; the last is a lower bound.
  static var servingsLowerBoundMarker: String {
    "6+"
  }

  static var servingsLowerBound: Int {
    6
  }

  /// Stands in for the backend's query engine. A parameter this does not recognise is
  /// ignored rather than treated as "match nothing" — an unknown parameter must never
  /// silently empty a screen.
  ///
  /// `sort=latest` needs no branch: the fixture is already stored newest-first, so
  /// accepting and ignoring it is the correct behaviour.
  func filtered(_ rows: [[String: Any]], for url: URL) -> [[String: Any]] {
    let filters = RecipeFilters(url: url)

    return rows
      .filter { matchesFacets($0, against: filters) }
      .filter { matchesIngredients($0, against: filters) }
      .filter { matchesSearch($0, against: filters) }
  }

  func matchesFacets(_ row: [String: Any], against filters: RecipeFilters) -> Bool {
    if let category = filters.category, !equals(row["category"], expected: category) {
      return false
    }

    if let cuisine = filters.cuisine, !equals(row["cuisine"], expected: cuisine) {
      return false
    }

    if let vegetarian = filters.isVegetarian, row["is_vegetarian"] as? Bool != vegetarian {
      return false
    }

    if let servings = filters.servings, !matchesServings(row, expected: servings) {
      return false
    }

    return true
  }

  /// The prototype's fourth serving option is a bound rather than a value, so it is
  /// matched separately. A value that is neither the bound nor a number is ignored — the
  /// same promise this type makes about an unrecognised parameter name.
  func matchesServings(_ row: [String: Any], expected servings: String) -> Bool {
    let count = row["servings"] as? Int ?? 0

    if servings == Self.servingsLowerBoundMarker {
      return count >= Self.servingsLowerBound
    }

    guard let wanted = Int(servings) else {
      return true
    }

    return count == wanted
  }

  /// Every included term must appear, and no excluded term may.
  func matchesIngredients(_ row: [String: Any], against filters: RecipeFilters) -> Bool {
    guard !filters.includedIngredients.isEmpty || !filters.excludedIngredients.isEmpty else {
      return true
    }

    let names = ingredientNames(in: row)

    func mentions(_ term: String) -> Bool {
      names.contains { $0.contains(fold(term)) }
    }

    return filters.includedIngredients.allSatisfy(mentions)
      && !filters.excludedIngredients.contains(where: mentions)
  }

  func matchesSearch(_ row: [String: Any], against filters: RecipeFilters) -> Bool {
    guard let search = filters.searchText.map(fold) else {
      return true
    }

    var haystack = ["title", "description", "category", "cuisine"]
      .compactMap { row[$0] as? String }
      .map(fold)

    haystack += ingredientNames(in: row)

    if filters.searchesSteps {
      haystack += (row["steps"] as? [String] ?? []).map(fold)
    }

    return haystack.contains { $0.contains(search) }
  }

  func ingredientNames(in row: [String: Any]) -> [String] {
    (row["ingredients"] as? [[String: Any]] ?? [])
      .compactMap { $0["name"] as? String }
      .map(fold)
  }

  func equals(_ stored: Any?, expected wanted: String) -> Bool {
    (stored as? String).map { fold($0) == fold(wanted) } ?? false
  }

  /// Case- and diacritic-insensitive, so `jamon` finds `jamón`.
  ///
  /// Deliberately locale-independent: under a Turkish locale `.current` would fold `I` to
  /// a dotless `ı`, and a search for `Italian` would stop matching `italian`.
  func fold(_ value: String) -> String {
    value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
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
