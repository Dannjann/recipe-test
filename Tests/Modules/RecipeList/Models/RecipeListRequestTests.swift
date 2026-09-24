//
//  RecipeListRequestTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeListRequestTests {
  @Test
  func category_filtersOnTheCategoryItIsTitledWith() {
    let request = RecipeListRequest.category(.dummy(name: "Desserts"))

    #expect(request.query.category == "Desserts")
    #expect(request.title == .category("Desserts"))
  }

  @Test
  func search_carriesTheTextIntoBothTheQueryAndTheTitle() {
    let request = RecipeListRequest.search(
      "adobo",
      query: RecipeQuery(isVegetarian: true)
    )

    #expect(request.query.searchText == "adobo")
    #expect(request.query.isVegetarian == true)
    #expect(request.title == .search("adobo"))
  }

  @Test
  func all_keepsTheFacetsItWasGivenAndIsTitledForEverything() {
    let request = RecipeListRequest.all(query: RecipeQuery(servings: .two))

    #expect(request.query.servings == .two)
    #expect(request.query.category == nil)
    #expect(request.title == .all)
  }

  @Test
  func isHashable_soItCanRideANavigationPath() {
    let request = RecipeListRequest.category(.dummy(name: "Rice"))

    #expect(Set([request, request]).count == 1)
  }
}
