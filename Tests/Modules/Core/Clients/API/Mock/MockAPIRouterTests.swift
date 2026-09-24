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

  // MARK: - Filtering

  /// The router stands in for the backend's query engine. A parameter it does not know
  /// must be ignored, not treated as "match nothing" — otherwise a stray query string
  /// empties a screen and looks exactly like "no results".
  @Test
  func recipes_withAnUnknownParameter_returnsTheSameRows() throws {
    let all = try matches("recipes?per_page=100")
    let same = try matches("recipes?per_page=100&flavour=umami")

    #expect(all.isEmpty == false)
    #expect(all.count == same.count)
  }

  /// Every filter must actually reduce the set. A filter that silently passes everything
  /// is indistinguishable from a working one until someone counts the rows.
  @Test
  func recipes_everyFilter_reducesTheSet() throws {
    let all = try matches("recipes?per_page=100").count

    for query in [
      "category=Pasta",
      "cuisine=italian",
      "is_vegetarian=true",
      "servings=2",
      "include_ingredients=garlic",
      "exclude_ingredients=garlic",
      "search_text=curry",
    ] {
      let filtered = try matches("recipes?per_page=100&\(query)")

      #expect(filtered.isEmpty == false, "\(query) matched nothing")
      #expect(filtered.count < all, "\(query) did not filter")
    }
  }

  /// The prototype prints "*n* recipes" off this number. Counting the collection instead
  /// of the matches would make it wrong on every filtered screen.
  @Test
  func recipes_whenFiltered_metaTotalCountsMatchesNotTheCollection() throws {
    let envelope = try decode(makeSUT().response(for: makeRequest("/api/v1/recipes?per_page=1&category=Pasta")).body)
    let meta = try #require(envelope["meta"] as? [String: Any])

    #expect(rows(in: envelope).count == 1)
    #expect(meta["total"] as? Int == 2)
    #expect(meta["last_page"] as? Int == 2)
  }

  /// `6+` is a lower bound, not a value — the prototype's fourth serving option.
  @Test
  func recipes_withSixOrMoreServings_treatsItAsALowerBound() throws {
    let matched = try matches("recipes?per_page=100&servings=6%2B")

    #expect(matched.isEmpty == false)
    #expect(matched.allSatisfy { ($0["servings"] as? Int ?? 0) >= 6 })
  }

  /// The fixture carries `jamón ibérico` and `béchamel`. A user typing plain ASCII must
  /// still find them — which means the *haystack* has to be folded, not just the term.
  /// A term-only test passes against ASCII data and proves nothing.
  @Test
  func recipes_searchIgnoresCaseAndDiacritics() throws {
    let plain = try matches("recipes?per_page=100&search_text=jamon")
    let accented = try matches("recipes?per_page=100&search_text=jam%C3%B3n")
    let shouted = try matches("recipes?per_page=100&search_text=JAMON")

    #expect(plain.isEmpty == false)
    #expect(plain.count == accented.count)
    #expect(plain.count == shouted.count)
  }

  /// An unrecognised *value* on a recognised parameter must be ignored, exactly like an
  /// unrecognised parameter — not quietly become a filter for the opposite rows.
  @Test
  func recipes_withAnUnparseableBooleanValue_ignoresTheFilter() throws {
    let all = try matches("recipes?per_page=100")
    let nonsense = try matches("recipes?per_page=100&is_vegetarian=banana")

    #expect(nonsense.count == all.count)
  }

  /// An unrecognised servings value must be ignored too. `count == Int(servings)`
  /// compared `Int` against `Int?`, which is false for every row, so a stray value
  /// emptied the list instead of being ignored.
  @Test
  func recipes_withAnUnparseableServingsValue_ignoresTheFilter() throws {
    let all = try matches("recipes?per_page=100")
    let nonsense = try matches("recipes?per_page=100&servings=many")

    #expect(nonsense.count == all.count)
  }

  /// Recipe facets must not reach the categories fixture: no tile carries those keys, so
  /// filtering it would answer 200 with an empty grid.
  @Test
  func categories_withARecipeFacet_stillReturnsEveryTile() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/categories?category=Pasta"))

    #expect(result.status == 200)
    #expect(try rows(in: decode(result.body)).count == 6)
  }

  /// Both spellings a URL encoder might produce mean the same thing to the router.
  @Test
  func recipes_acceptsNumericAndLiteralBooleans() throws {
    let literal = try matches("recipes?per_page=100&is_vegetarian=true")
    let numeric = try matches("recipes?per_page=100&is_vegetarian=1")

    #expect(literal.isEmpty == false)
    #expect(literal.count == numeric.count)
  }

  @Test
  func recipes_includeIngredients_requiresEveryTerm() throws {
    let one = try matches("recipes?per_page=100&include_ingredients=garlic")
    let two = try matches("recipes?per_page=100&include_ingredients=garlic&include_ingredients=onion")

    #expect(two.count < one.count)
    #expect(two.isEmpty == false)
  }

  @Test
  func recipes_excludeIngredients_forbidsEveryTerm() throws {
    let without = try matches("recipes?per_page=100&exclude_ingredients=garlic")

    #expect(without.isEmpty == false)
    #expect(without.allSatisfy { row in
      let names = (row["ingredients"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }

      return names.allSatisfy { !$0.lowercased().contains("garlic") }
    })
  }

  /// The prototype's "search in steps" toggle. Off, instruction text is not searched.
  @Test
  func recipes_searchesSteps_widensTheSearchToInstructions() throws {
    let narrow = try matches("recipes?per_page=100&search_text=simmer")
    let wide = try matches("recipes?per_page=100&search_text=simmer&searches_steps=true")

    #expect(wide.count > narrow.count)
  }

  /// `sort=latest` is fixture order, so it is accepted and ignored rather than rejected.
  @Test
  func recipes_sortLatest_isAcceptedAndChangesNothing() throws {
    let plain = try matches("recipes?per_page=5")
    let sorted = try matches("recipes?per_page=5&sort=latest")

    #expect(plain.map { $0["id"] as? String } == sorted.map { $0["id"] as? String })
  }

  /// Filters combine, rather than the last one winning.
  @Test
  func recipes_filtersCombine() throws {
    let matched = try matches("recipes?per_page=100&category=Desserts&is_vegetarian=true")

    #expect(matched.isEmpty == false)
    #expect(matched.allSatisfy { $0["category"] as? String == "Desserts" })
    #expect(matched.allSatisfy { $0["is_vegetarian"] as? Bool == true })
  }

  // MARK: - Categories

  @Test
  func categories_returnsTheBrowseTiles() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/categories"))

    #expect(result.status == 200)

    let envelope = try decode(result.body)
    #expect(rows(in: envelope).count == 6)
    // A collection that is not paginated carries no meta.
    #expect(envelope.keys.contains("meta") == false)
  }

  /// Photographs are real URLs on real hosts now; the mock must not answer for them.
  @Test
  func anImagePath_returns404() throws {
    let result = try makeSUT().response(for: makeRequest("/api/v1/images/carbonara.png"))

    #expect(result.status == 404)
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

  /// The rows a query matches, unwrapped out of the envelope.
  func matches(_ query: String) throws -> [[String: Any]] {
    try rows(in: decode(makeSUT().response(for: makeRequest("/api/v1/\(query)")).body))
  }

  func rows(in envelope: [String: Any]) -> [[String: Any]] {
    envelope["data"] as? [[String: Any]] ?? []
  }
}
