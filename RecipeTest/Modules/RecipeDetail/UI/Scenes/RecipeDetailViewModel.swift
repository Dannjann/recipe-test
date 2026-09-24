//
//  RecipeDetailViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class RecipeDetailViewModel: RecipeDetailViewModelProtocol {
  private(set) var detail: SectionState<Recipe> = .loading
  private(set) var checkedIngredientIDs: Set<String> = []

  private let summary: RecipeSummary

  private var detailGeneration = 0

  private let recipeService: RecipeServiceProtocol

  init(
    summary: RecipeSummary,
    recipeService: RecipeServiceProtocol
  ) {
    self.summary = summary
    self.recipeService = recipeService
  }
}

// MARK: - Getters

extension RecipeDetailViewModel {
  /// The loaded recipe is the fresher read of the same record; the summary stands in
  /// until it arrives, which is what lets the header paint on the first frame.
  var title: String {
    detail.value?.title ?? summary.title
  }

  /// Only the recipe carries prose, so there is nothing to fall back to.
  var descriptionText: String {
    detail.value?.description ?? ""
  }

  /// Reproduces the prototype's `fmtTime` — "25 min", "1 hr 25 min" — and localizes the
  /// units rather than assembling them by hand.
  var cookingTimeText: String? {
    guard let totalTimeMinutes else { return nil }

    return Duration
      .seconds(totalTimeMinutes * 60)
      .formatted(.units(
        allowed: [.hours, .minutes],
        width: .abbreviated
      ))
  }

  var servingsText: String? {
    servings.map { String($0) }
  }

  /// Left as a resource rather than a `String` so the view resolves it in its own
  /// environment, which is what lets it follow a locale override.
  var difficultyText: LocalizedStringResource? {
    switch difficulty {
    case .easy:
      .RecipeDetail.recipeDetailDifficultyEasy

    case .medium:
      .RecipeDetail.recipeDetailDifficultyMedium

    case .hard:
      .RecipeDetail.recipeDetailDifficultyHard

    case nil:
      nil
    }
  }

  /// The summary carries one photograph, the recipe the whole set. `gallery[0]` is the
  /// hero in every record the API serves, so the swap adds photographs rather than
  /// replacing the one already on screen.
  var galleryURLs: [URL] {
    if let gallery = detail.value?.gallery, !gallery.isEmpty {
      return gallery
    }

    return [detail.value?.heroImageURL ?? summary.heroImageURL].compactMap(\.self)
  }
}

// MARK: - Getters > Raw

private extension RecipeDetailViewModel {
  var totalTimeMinutes: Int? {
    detail.value?.totalTimeMinutes ?? summary.totalTimeMinutes
  }

  var servings: Int? {
    detail.value?.servings ?? summary.servings
  }

  var difficulty: RecipeDifficulty? {
    detail.value?.difficulty ?? summary.difficulty
  }
}

// MARK: - Inputs

extension RecipeDetailViewModel {
  func loadDetail() async {
    detailGeneration += 1
    let generation = detailGeneration
    let previous = detail
    detail = previous.refreshing

    do {
      let recipe = try await recipeService.getRecipe(id: summary.id)

      guard generation == detailGeneration else { return }

      detail = .loaded(recipe)
    } catch {
      guard generation == detailGeneration else { return }

      detail = previous.recovering(from: error)
    }
  }

  func toggleIngredient(id: String) {
    checkedIngredientIDs.formSymmetricDifference([id])
  }
}
