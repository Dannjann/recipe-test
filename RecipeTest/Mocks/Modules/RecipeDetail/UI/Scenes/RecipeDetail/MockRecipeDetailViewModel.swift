//
//  MockRecipeDetailViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  @Observable
  final class MockRecipeDetailViewModel: RecipeDetailViewModelProtocol {
    let summary: RecipeSummary

    var detail: SectionState<Recipe>
    var checkedIngredientIDs: Set<String>

    init(
      summary: RecipeSummary = .dummy(),
      detail: SectionState<Recipe> = .loading,
      checkedIngredientIDs: Set<String> = []
    ) {
      self.summary = summary
      self.detail = detail
      self.checkedIngredientIDs = checkedIngredientIDs
    }

    func loadDetail() async {}

    func toggleIngredient(id: String) {
      if checkedIngredientIDs.contains(id) {
        checkedIngredientIDs.remove(id)
      } else {
        checkedIngredientIDs.insert(id)
      }
    }
  }

  // MARK: - Getters

  extension MockRecipeDetailViewModel {
    var title: String {
      detail.value?.title ?? summary.title
    }

    var totalTimeMinutes: Int? {
      detail.value?.totalTimeMinutes ?? summary.totalTimeMinutes
    }

    var servings: Int? {
      detail.value?.servings ?? summary.servings
    }

    var difficulty: RecipeDifficulty? {
      detail.value?.difficulty ?? summary.difficulty
    }

    var galleryURLs: [URL] {
      if let gallery = detail.value?.gallery, !gallery.isEmpty {
        return gallery
      }

      return [summary.heroImageURL].compactMap { $0 }
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
      MockRecipeDetailViewModel(detail: .failed("The Internet connection appears to be offline."))
    }

    /// No photograph on the summary and none on the recipe — the case a card with a nil
    /// `heroImageURL` leads to.
    static func noPhotographs() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        summary: .dummy(heroImageURL: nil),
        detail: .loaded(.dummy(
          heroImageURL: nil,
          gallery: []
        ))
      )
    }

    static func partiallyChecked() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        detail: .loaded(.dummy()),
        checkedIngredientIDs: ["rcp-001-0", "rcp-001-3"]
      )
    }

    /// Every optional metric absent, so the em dash and its VoiceOver copy are visible.
    static func missingMetrics() -> MockRecipeDetailViewModel {
      MockRecipeDetailViewModel(
        summary: .dummy(
          totalTimeMinutes: nil,
          servings: nil,
          difficulty: nil
        ),
        detail: .loaded(.dummy(
          totalTimeMinutes: nil,
          servings: nil,
          difficulty: nil
        ))
      )
    }
  }
#endif
