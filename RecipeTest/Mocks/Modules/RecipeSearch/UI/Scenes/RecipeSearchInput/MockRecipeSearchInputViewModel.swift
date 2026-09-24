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
    var queryRow: (any RecipeSuggestionRowViewModelProtocol)?
    var sections: SectionState<[RecipeSuggestionSectionViewModel]>
    var emptyText: LocalizedStringResource

    init(
      queryRow: (any RecipeSuggestionRowViewModelProtocol)? = nil,
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
  }

  // MARK: - Fixtures

  extension MockRecipeSearchInputViewModel {
    static func recents() -> MockRecipeSearchInputViewModel {
      MockRecipeSearchInputViewModel(sections: .loaded([
        RecipeSuggestionSectionViewModel(
          id: .recent,
          title: .RecipeSearch.recipeSearchSuggestionSectionRecent,
          rows: ["pho", "adobo", "pandesal"].map {
            RecipeRecentSuggestionRowViewModel(text: $0)
          }
        ),
      ]))
    }

    static func matches() -> MockRecipeSearchInputViewModel {
      MockRecipeSearchInputViewModel(
        queryRow: RecipeQuerySuggestionRowViewModel(text: "ado"),
        sections: .loaded([
          RecipeSuggestionSectionViewModel(
            id: .categories,
            title: .RecipeSearch.recipeSearchSuggestionSectionCategories,
            rows: [RecipeCategorySuggestionRowViewModel(category: .dummy(name: "Meal"))]
          ),
          RecipeSuggestionSectionViewModel(
            id: .recipes,
            title: .RecipeSearch.recipeSearchSuggestionSectionRecipes,
            rows: [
              RecipeSummarySuggestionRowViewModel(summary: .dummy(
                id: "rcp-001",
                title: "Chicken Adobo"
              )),
            ]
          ),
        ]),
        emptyText: .RecipeSearch.recipeSearchSuggestionEmptyMatches
      )
    }
  }
#endif
