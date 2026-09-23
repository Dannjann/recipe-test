//
//  MockAPIRouterTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// Reads the shipped `recipes.json` out of the host app bundle, so these assertions are
/// against what the demo build actually serves.
struct MockAPIRouterTests {
  @Test
  func recipes_returnsAPageOfRows() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes?page=1&per_page=5"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).count == 5)
    #expect(rows(in: envelope).first?["id"] as? String == "rcp-001")

    let meta = try #require(envelope["meta"] as? [String: Any])
    #expect(meta["total"] as? Int == 36)
    #expect(meta["current_page"] as? Int == 1)
    #expect(meta["last_page"] as? Int == 8)
  }

  @Test
  func recipes_secondPage_startsAfterTheFirst() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes?page=2&per_page=5"))

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).first?["id"] as? String == "rcp-006")
  }

  /// A page past the end is an empty page, not an error — which is what a real paginated
  /// API does. The meta still reports the page that was asked for, so `hasLoadedAllData`
  /// is what has to stop the pager.
  @Test
  func recipes_pastTheLastPage_returnsAnEmptyPage() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes?page=99&per_page=5"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).isEmpty)

    let meta = try #require(envelope["meta"] as? [String: Any])
    #expect(meta["current_page"] as? Int == 99)
    #expect(meta["last_page"] as? Int == 8)
  }

  @Test
  func recipe_returnsTheMatchingRowAsAnObject() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes/rcp-007"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    let data = try #require(envelope["data"] as? [String: Any])
    #expect(data["id"] as? String == "rcp-007")
    #expect(data["steps"] != nil)
    // A single resource carries no pagination.
    #expect(envelope.keys.contains("meta") == false)
  }

  /// A 404, not an empty array the caller would then fail to decode into a recipe.
  @Test
  func recipe_withAnUnknownID_returns404() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/recipes/rcp-999"))

    #expect(result.status == 404)

    let envelope = try decode(result.body)
    #expect(envelope["http_status"] as? Int == 404)
  }

  @Test
  func recipe_inEmptyFailureMode_returns404() throws {
    let result = try makeSUT(failureMode: .empty).response(for: makeRequest("/api/v1/recipes/rcp-001"))

    #expect(result.status == 404)
  }

  @Test
  func recipes_inEmptyFailureMode_returnsZeroRows() throws {
    let result = try makeSUT(failureMode: .empty).response(for: makeRequest("/api/v1/recipes?per_page=5"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).isEmpty)
    #expect((envelope["meta"] as? [String: Any])?["total"] as? Int == 0)
  }

  @Test
  func recipes_inServerErrorMode_returns500() throws {
    let result = try makeSUT(failureMode: .serverError).response(for: makeRequest("/api/v1/recipes"))

    #expect(result.status == 500)
  }

  @Test
  func anUnregisteredPath_returns404() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/authors"))

    #expect(result.status == 404)
  }
}

// MARK: - Helpers

private extension MockAPIRouterTests {
  func makeSUT(failureMode: MockAPIRouter.FailureMode = .none) -> MockAPIRouter {
    MockAPIRouter(configuration: .init(latency: .zero, failureMode: failureMode))
  }

  func makeRequest(_ path: String) -> URLRequest {
    URLRequest(url: URL(string: "https://api.example.com\(path)")!)
  }

  func decode(_ body: Data) throws -> [String: Any] {
    try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
  }

  func rows(in envelope: [String: Any]) -> [[String: Any]] {
    envelope["data"] as? [[String: Any]] ?? []
  }
}
