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
    #expect(RecipeQuerySuggestionRowViewModel(text: "ado").title.contains("ado"))
  }

  @Test
  func symbolName_theTextRows_standInForAMissingPhotograph() {
    #expect(RecipeQuerySuggestionRowViewModel(text: "ado").symbolName == "magnifyingglass")
    #expect(RecipeRecentSuggestionRowViewModel(text: "pho").symbolName == "clock")
  }

  @Test
  func imageURL_aRecipeRow_carriesTheHeroImage() {
    let summary = RecipeSummary.dummy(id: "rcp-001")
    let row = RecipeSummarySuggestionRowViewModel(summary: summary)

    #expect(row.imageURL == summary.heroImageURL)
    #expect(row.symbolName == "fork.knife")
  }

  @Test
  func detail_aRecipeWithNoCuisine_fallsBackRatherThanReadingEmpty() {
    let row = RecipeSummarySuggestionRowViewModel(summary: .dummy(cuisine: nil))

    #expect(!row.detail.isEmpty)
  }

  @Test
  func id_everyKind_isPrefixedByIt() {
    #expect(RecipeQuerySuggestionRowViewModel(text: "a").id.hasPrefix("query-"))
    #expect(RecipeRecentSuggestionRowViewModel(text: "a").id.hasPrefix("recent-"))
    #expect(RecipeCategorySuggestionRowViewModel(category: .dummy()).id.hasPrefix("category-"))
    #expect(RecipeSummarySuggestionRowViewModel(summary: .dummy()).id.hasPrefix("recipe-"))
  }
}

// MARK: - Selection

/// What picking a row means now belongs to the row itself, so each kind answers for itself
/// rather than a switch elsewhere deciding on its behalf.
extension RecipeSuggestionRowViewModelTests {
  @Test
  func selection_aRecipeRow_carriesTheRecipe() {
    let summary = RecipeSummary.dummy(id: "rcp-007")

    #expect(RecipeSummarySuggestionRowViewModel(summary: summary).selection == .recipe(summary))
  }

  @Test
  func selection_aCategoryRow_fillsTheFieldWithItsName() {
    let row = RecipeCategorySuggestionRowViewModel(category: .dummy(name: "Desserts"))

    #expect(row.selection == .text("Desserts"))
  }

  @Test
  func selection_aRecentRow_fillsTheFieldWithIt() {
    #expect(RecipeRecentSuggestionRowViewModel(text: "pho").selection == .text("pho"))
  }

  @Test
  func selection_aQueryRow_fillsTheFieldWithWhatWasTyped() {
    #expect(RecipeQuerySuggestionRowViewModel(text: "ado").selection == .text("ado"))
  }
}

// MARK: - Rendered identity

/// `SectionState` equality drives whether SwiftUI leaves a section alone, and an array of
/// existentials has no synthesised `==` — so the substitute has to be tested.
extension RecipeSuggestionRowViewModelTests {
  @Test
  func renderedIdentity_twoRowsOverTheSameValue_match() {
    #expect(RecipeRecentSuggestionRowViewModel(text: "pho").renderedIdentity
      == RecipeRecentSuggestionRowViewModel(text: "pho").renderedIdentity)
  }

  @Test
  func renderedIdentity_sameIdButADifferentTitle_differs() {
    let first = RecipeSummarySuggestionRowViewModel(summary: .dummy(
      id: "rcp-001",
      title: "Chicken Adobo"
    ))
    let renamed = RecipeSummarySuggestionRowViewModel(summary: .dummy(
      id: "rcp-001",
      title: "Pork Adobo"
    ))

    #expect(first.id == renamed.id)
    #expect(first.renderedIdentity != renamed.renderedIdentity)
  }
}
