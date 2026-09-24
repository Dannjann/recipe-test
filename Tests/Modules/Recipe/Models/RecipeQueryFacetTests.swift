//
//  RecipeQueryFacetTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeQueryFacetTests {
  @Test
  func activeFacets_emptyQuery_isEmpty() {
    #expect(RecipeQuery.empty.activeFacets.isEmpty)
  }

  @Test
  func activeFacets_vegetarianFalse_isStillAFacet() {
    let query = RecipeQuery(isVegetarian: false)

    #expect(query.activeFacets == [.vegetarian(false)])
  }

  @Test
  func activeFacets_everyFacetSet_listsThemInDisplayOrder() {
    let query = RecipeQuery(
      isVegetarian: true,
      servings: .four,
      includeIngredients: ["garlic"],
      excludeIngredients: ["peanuts"],
      searchesSteps: true
    )

    #expect(query.activeFacets == [
      .vegetarian(true),
      .servings(.four),
      .include("garlic"),
      .exclude("peanuts"),
      .searchesSteps,
    ])
  }

  @Test
  func activeFacets_aRepeatedIngredient_isOneFacet() {
    let query = RecipeQuery(
      includeIngredients: ["garlic", "garlic", "ginger"],
      excludeIngredients: ["peanuts", "peanuts"]
    )

    #expect(query.activeFacets == [
      .include("garlic"),
      .include("ginger"),
      .exclude("peanuts"),
    ])
  }

  @Test
  func activeFacets_categorySearchTextAndSort_areNotFacets() {
    let query = RecipeQuery(
      searchText: "adobo",
      category: "Desserts",
      sort: .latest
    )

    #expect(query.activeFacets.isEmpty)
  }

  @Test
  func removing_dropsOnlyTheNamedFacet() {
    let query = RecipeQuery(
      isVegetarian: true,
      servings: .two
    )

    let result = query.removing(.vegetarian(true))

    #expect(result.isVegetarian == nil)
    #expect(result.servings == .two)
  }

  @Test
  func removing_anIngredient_leavesItsSiblings() {
    let query = RecipeQuery(includeIngredients: [
      "garlic",
      "onion",
    ])

    let result = query.removing(.include("garlic"))

    #expect(result.includeIngredients == ["onion"])
  }

  @Test
  func removing_keepsTheCategoryAndSearchText() {
    let query = RecipeQuery(
      searchText: "adobo",
      category: "Meal",
      isVegetarian: true
    )

    let result = query.removing(.vegetarian(true))

    #expect(result.searchText == "adobo")
    #expect(result.category == "Meal")
  }

  @Test
  func clearingFacets_dropsEveryFacetAndKeepsTheScope() {
    let query = RecipeQuery(
      searchText: "adobo",
      category: "Meal",
      isVegetarian: false,
      servings: .sixOrMore,
      includeIngredients: ["garlic"],
      excludeIngredients: ["peanuts"],
      searchesSteps: true
    )

    let result = query.clearingFacets()

    #expect(result.activeFacets.isEmpty)
    #expect(result.searchText == "adobo")
    #expect(result.category == "Meal")
  }
}
