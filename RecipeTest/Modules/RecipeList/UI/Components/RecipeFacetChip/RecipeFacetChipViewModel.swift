//
//  RecipeFacetChipViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

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

  var backgroundColorStyle: Color.ThemeColor {
    isExclusion ? .complementaryShade3 : .surfacesFieldsAndTags
  }

  var accessibilityIdentifier: String {
    "recipe-list-facet-chip-\(identifierSuffix)-remove-button"
  }
}

// MARK: - Getters > Constants

private nonisolated extension RecipeFacetChipViewModel {
  var isExclusion: Bool {
    if case .exclude = facet {
      return true
    }

    return false
  }

  var identifierSuffix: String {
    switch facet {
    case .vegetarian:
      "vegetarian"

    case .servings:
      "servings"

    case let .include(ingredient):
      "include-\(ingredient)"

    case let .exclude(ingredient):
      "exclude-\(ingredient)"

    case .searchesSteps:
      "searches-steps"
    }
  }
}
