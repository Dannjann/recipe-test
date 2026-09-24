//
//  MockRecipeSearchInputViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  @Observable
  final class MockRecipeSearchInputViewModel: RecipeSearchInputViewModelProtocol {
    var queryRow: RecipeSuggestionRowViewModel?
    var sections: SectionState<[RecipeSuggestionSectionViewModel]>
    var emptyText: LocalizedStringResource

    init(
      queryRow: RecipeSuggestionRowViewModel? = nil,
      sections: SectionState<[RecipeSuggestionSectionViewModel]> = .empty,
      emptyText: LocalizedStringResource = .RecipeSearch.recipeSearchSuggestionEmptyIdle
    ) {
      self.queryRow = queryRow
      self.sections = sections
      self.emptyText = emptyText
    }
  }

  // MARK: - Inputs

  extension MockRecipeSearchInputViewModel {
    func update(text _: String) async {}

    func select(_ row: RecipeSuggestionRowViewModel) -> RecipeSearchInputSelection {
      switch row.suggestion {
      case let .query(text), let .recent(text):
        .text(text)

      case let .category(category):
        .text(category.name)

      case let .recipe(summary):
        .recipe(summary)
      }
    }
  }

  // MARK: - Fixtures

  extension MockRecipeSearchInputViewModel {
    static func recents() -> MockRecipeSearchInputViewModel {
      MockRecipeSearchInputViewModel(sections: .loaded([
        RecipeSuggestionSectionViewModel(
          id: "recent",
          title: .RecipeSearch.recipeSearchSuggestionSectionRecent,
          rows: ["pho", "adobo", "pandesal"].map {
            RecipeSuggestionRowViewModel(suggestion: .recent($0))
          }
        ),
      ]))
    }

    static func matches() -> MockRecipeSearchInputViewModel {
      MockRecipeSearchInputViewModel(
        queryRow: RecipeSuggestionRowViewModel(suggestion: .query("ado")),
        sections: .loaded([
          RecipeSuggestionSectionViewModel(
            id: "categories",
            title: .RecipeSearch.recipeSearchSuggestionSectionCategories,
            rows: [RecipeSuggestionRowViewModel(suggestion: .category(.dummy(name: "Meal")))]
          ),
          RecipeSuggestionSectionViewModel(
            id: "recipes",
            title: .RecipeSearch.recipeSearchSuggestionSectionRecipes,
            rows: [
              RecipeSuggestionRowViewModel(suggestion: .recipe(.dummy(
                id: "rcp-001",
                title: "Chicken Adobo"
              ))),
            ]
          ),
        ]),
        emptyText: .RecipeSearch.recipeSearchSuggestionEmptyMatches
      )
    }
  }
#endif
