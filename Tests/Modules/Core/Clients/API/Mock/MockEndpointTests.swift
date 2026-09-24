//
//  MockEndpointTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct MockEndpointTests {
  @Test
  func match_theRecipesCollection() {
    #expect(MockEndpoint.match(path: "/api/v1/recipes", method: "GET") == .recipes)
  }

  @Test
  func match_aRecipeByID() {
    #expect(MockEndpoint.match(path: "/api/v1/recipes/rcp-001", method: "GET") == .recipe(id: "rcp-001"))
  }

  /// Photographs are real URLs on real hosts now, so the mock must not claim an image
  /// path — anything it matched here it would answer with a generated tile instead.
  @Test
  func match_anImagePath_isNotMocked() {
    #expect(MockEndpoint.match(path: "/api/v1/images/carbonara.png", method: "GET") == nil)
  }

  /// An unregistered path is a 404 rather than a silent success, so a typo in a resource
  /// path fails the way it would against a real backend.
  @Test
  func match_anUnknownPath_returnsNil() {
    #expect(MockEndpoint.match(path: "/api/v1/authors", method: "GET") == nil)
  }

  @Test
  func match_aNonGETRequest_returnsNil() {
    #expect(MockEndpoint.match(path: "/api/v1/recipes", method: "POST") == nil)
  }

  @Test
  func fixtureRowID_isSetOnlyForADetailEndpoint() {
    #expect(MockEndpoint.recipe(id: "rcp-001").fixtureRowID == "rcp-001")
    #expect(MockEndpoint.recipes.fixtureRowID == nil)
  }

  @Test
  func isPaginated_isTrueOnlyForTheCollection() {
    #expect(MockEndpoint.recipes.isPaginated)
    #expect(MockEndpoint.recipe(id: "rcp-001").isPaginated == false)
  }

  @Test
  func fixtureName_isTheSharedCollectionForBothRecipeEndpoints() {
    #expect(MockEndpoint.recipes.fixtureName == "recipes")
    #expect(MockEndpoint.recipe(id: "rcp-001").fixtureName == "recipes")
  }
}
