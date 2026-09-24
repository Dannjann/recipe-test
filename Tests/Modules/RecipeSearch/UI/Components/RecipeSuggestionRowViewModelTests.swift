//
//  RecipeSuggestionRowViewModelTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct RecipeSuggestionRowViewModelTests {
  @Test
  func title_aQueryRow_splicesInWhatWasTyped() {
    let row = RecipeSuggestionRowViewModel(suggestion: .query("ado"))

    #expect(row.title.contains("ado"))
  }

  @Test
  func symbolName_theTextRows_standInForAMissingPhotograph() {
    #expect(RecipeSuggestionRowViewModel(suggestion: .query("ado")).symbolName == "magnifyingglass")
    #expect(RecipeSuggestionRowViewModel(suggestion: .recent("pho")).symbolName == "clock")
  }

  @Test
  func imageURL_aRecipeRow_carriesTheHeroImage() {
    let summary = RecipeSummary.dummy(id: "rcp-001")
    let row = RecipeSuggestionRowViewModel(suggestion: .recipe(summary))

    #expect(row.imageURL == summary.heroImageURL)
    #expect(row.symbolName == nil)
  }

  @Test
  func detail_aRecipeWithNoCuisine_fallsBackRatherThanReadingEmpty() {
    let summary = RecipeSummary.dummy(cuisine: nil)
    let row = RecipeSuggestionRowViewModel(suggestion: .recipe(summary))

    #expect(!row.detail.isEmpty)
  }

  @Test
  func id_everyCase_isPrefixedByItsKind() {
    #expect(RecipeSuggestionRowViewModel(suggestion: .query("a")).id.hasPrefix("query-"))
    #expect(RecipeSuggestionRowViewModel(suggestion: .recent("a")).id.hasPrefix("recent-"))
    #expect(RecipeSuggestionRowViewModel(suggestion: .category(.dummy())).id.hasPrefix("category-"))
    #expect(RecipeSuggestionRowViewModel(suggestion: .recipe(.dummy())).id.hasPrefix("recipe-"))
  }
}
