//
//  RecipeFacetChipViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeFacetChipViewModel: RecipeFacetChipViewModelProtocol {
  let facet: RecipeQueryFacet
}

// MARK: - Getters

nonisolated extension RecipeFacetChipViewModel {
  var id: RecipeQueryFacet {
    facet
  }

  /// `RecipeServings.rawValue` is already the display string the prototype shows — "1", "2",
  /// "4", "6+" — which is why the fourth option is an enum and not an `Int`.
  var label: String {
    switch facet {
    case let .vegetarian(isVegetarian):
      isVegetarian
        ? String(localized: .RecipeList.recipeListFacetVegetarian)
        : String(localized: .RecipeList.recipeListFacetNotVegetarian)

    case let .servings(servings):
      String(localized: .RecipeList.recipeListFacetServings(servings.rawValue))

    case let .include(ingredient):
      String(localized: .RecipeList.recipeListFacetInclude(ingredient))

    case let .exclude(ingredient):
      String(localized: .RecipeList.recipeListFacetExclude(ingredient))

    case .searchesSteps:
      String(localized: .RecipeList.recipeListFacetSearchesSteps)
    }
  }

  var removeAccessibilityLabel: String {
    String(localized: .RecipeList.recipeListFacetRemoveAccessibilityLabel(label))
  }

  var isExclusion: Bool {
    if case .exclude = facet {
      return true
    }

    return false
  }
}
