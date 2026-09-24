//
//  RecipeQueryTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeQueryTests {
  /// An unfiltered list request must carry only paging. Nine empty parameters would make
  /// the router filter on the empty string.
  @Test
  func queryParameters_whenEmpty_encodesToNothing() throws {
    #expect(try RecipeQuery.empty.queryParameters().isEmpty)
  }

  @Test
  func queryParameters_encodesEveryFacetUnderItsWireName() throws {
    let sut = RecipeQuery(
      searchText: "garlic",
      category: "Vegan",
      cuisine: "thai",
      isVegetarian: true,
      servings: .sixOrMore,
      includeIngredients: ["garlic", "onion"],
      excludeIngredients: ["peanut"],
      searchesSteps: true,
      sort: .latest
    )

    let parameters = try sut.queryParameters()

    #expect(parameters["search_text"] as? String == "garlic")
    #expect(parameters["category"] as? String == "Vegan")
    #expect(parameters["cuisine"] as? String == "thai")
    #expect(parameters["is_vegetarian"] as? Bool == true)
    #expect(parameters["servings"] as? String == "6+")
    #expect(parameters["include_ingredients"] as? [String] == ["garlic", "onion"])
    #expect(parameters["exclude_ingredients"] as? [String] == ["peanut"])
    #expect(parameters["searches_steps"] as? Bool == true)
    #expect(parameters["sort"] as? String == "latest")
  }

  @Test
  func queryParameters_withEmptyIngredientLists_omitsThem() throws {
    let parameters = try RecipeQuery(category: "Rice").queryParameters()

    #expect(parameters.keys.sorted() == ["category"])
  }

  /// `false` is a filter the user set, not an absence — unlike an empty list.
  @Test
  func queryParameters_withVegetarianFalse_stillSendsIt() throws {
    #expect(try RecipeQuery(isVegetarian: false).queryParameters()["is_vegetarian"] as? Bool == false)
  }

  /// `6+` is a lower bound, not a number, which is the whole reason servings is an enum.
  @Test
  func servings_rawValuesAreTheWireStrings() {
    #expect(RecipeServings.allCases.map(\.rawValue) == ["1", "2", "4", "6+"])
  }
}
