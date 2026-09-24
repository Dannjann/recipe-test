//
//  MockRecipeDetailViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  /// Holds its display values rather than deriving them, so a preview shows exactly what
  /// its scenario asked for and cannot drift as `RecipeDetailViewModel`'s getters change.
  @Observable
  final class MockRecipeDetailViewModel: RecipeDetailViewModelProtocol {
    var detail: SectionState<Recipe>
    var checkedIngredientIDs: Set<String>

    let title: String
    let descriptionText: String
    let cookingTimeText: String?
    let servingsText: String?
    let difficultyText: LocalizedStringResource?
    let galleryURLs: [URL]

    init(
      detail: SectionState<Recipe> = .loading,
      checkedIngredientIDs: Set<String> = [],
      title: String = "Spaghetti alla Carbonara",
      descriptionText: String = "Roman pasta bound with egg yolk and pecorino — never cream.",
      cookingTimeText: String? = "25 min",
      servingsText: String? = "4",
      difficultyText: LocalizedStringResource? = .RecipeDetail.recipeDetailDifficultyMedium,
      galleryURLs: [URL] = Recipe.dummy().gallery
    ) {
      self.detail = detail
      self.checkedIngredientIDs = checkedIngredientIDs
      self.title = title
      self.descriptionText = descriptionText
      self.cookingTimeText = cookingTimeText
      self.servingsText = servingsText
      self.difficultyText = difficultyText
      self.galleryURLs = galleryURLs
    }

    func loadDetail() async {}

    func toggleIngredient(id: String) {
      checkedIngredientIDs.formSymmetricDifference([id])
    }
  }

  // MARK: - Scenarios

  extension MockRecipeDetailViewModel {
    static func loaded() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .loaded(.dummy()))
    }

    static func loading() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .loading)
    }

    static func failed() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .failed(String(localized: .Shared.sharedErrorNoInternetConnection)))
    }

    /// No photograph on the summary and none on the recipe — the case a card with a nil
    /// `heroImageURL` leads to.
    static func noPhotographs() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        detail: .loaded(.dummy(
          heroImageURL: nil,
          gallery: []
        )),
        galleryURLs: []
      )
    }

    static func partiallyChecked() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        detail: .loaded(.dummy()),
        checkedIngredientIDs: ["rcp-001-0", "rcp-001-3"]
      )
    }

    /// A recipe that loaded with nothing to cook with — no ingredients, no steps.
    static func withoutABody() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(detail: .loaded(.dummy(
        ingredients: [],
        steps: []
      )))
    }

    /// Every optional metric absent, so the em dash and its VoiceOver copy are visible.
    static func missingMetrics() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        detail: .loaded(.dummy(
          totalTimeMinutes: nil,
          servings: nil,
          difficulty: nil
        )),
        cookingTimeText: nil,
        servingsText: nil,
        difficultyText: nil
      )
    }
  }
#endif
