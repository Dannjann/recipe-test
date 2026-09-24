//
//  RecipeSearchInputViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class RecipeSearchInputViewModel: RecipeSearchInputViewModelProtocol {
  private(set) var sections: SectionState<[RecipeSuggestionSectionViewModel]> = .empty

  private var text: String
  private var categories: [RecipeCategory] = []
  private var hasLoadedCategories = false

  /// `.task(id:)` cancels the previous call but does not wait for it: the successor runs its
  /// synchronous prefix first, and the cancelled one then resumes and would land its result
  /// over the newer state. Same mechanism `RecipeListViewModel` uses for the same reason.
  private var generation = 0

  private let debounce: Duration
  private let recipeService: RecipeServiceProtocol
  private let recentSearchStore: RecentSearchStoreProtocol

  init(
    text: String = "",
    debounce: Duration = .milliseconds(300),
    recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService,
    recentSearchStore: RecentSearchStoreProtocol = AppContainer.shared.recentSearchStore
  ) {
    self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    self.debounce = debounce
    self.recipeService = recipeService
    self.recentSearchStore = recentSearchStore
  }
}

// MARK: - Getters

extension RecipeSearchInputViewModel {
  var queryRow: RecipeSuggestionRowViewModel? {
    guard !text.isEmpty else { return nil }

    return RecipeSuggestionRowViewModel(suggestion: .query(text))
  }

  /// Two messages, because an empty list means two different things: nothing matched what was
  /// typed, or nothing has been searched for yet.
  var emptyText: LocalizedStringResource {
    text.isEmpty
      ? .RecipeSearch.recipeSearchSuggestionEmptyIdle
      : .RecipeSearch.recipeSearchSuggestionEmptyMatches
  }
}

// MARK: - Inputs

extension RecipeSearchInputViewModel {
  /// Driven from `.task(id: text)`, so SwiftUI cancels the previous call as the next keystroke
  /// lands: the sleep is the debounce, and that cancellation is what enforces it.
  func update(text: String) async {
    generation += 1
    let generation = self.generation
    self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !self.text.isEmpty else {
      sections = .rows(recentSections)
      return
    }

    let previous = sections
    sections = previous.refreshing

    do {
      try await Task.sleep(for: debounce)

      try await loadCategoriesIfNeeded()

      let page = try await recipeService.getRecipes(
        query: RecipeQuery(searchText: self.text),
        page: suggestionPage
      )

      guard generation == self.generation else { return }

      sections = .rows(matchSections(for: page.recipes))
    } catch {
      guard generation == self.generation else { return }

      sections = previous.recovering(from: error)
    }
  }

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

// MARK: - Helpers

private extension RecipeSearchInputViewModel {
  var recentSections: [RecipeSuggestionSectionViewModel] {
    let rows = recentSearchStore.searches
      .prefix(recentLimit)
      .map { RecipeSuggestionRowViewModel(suggestion: .recent($0)) }

    guard !rows.isEmpty else { return [] }

    return [RecipeSuggestionSectionViewModel(
      id: "recent",
      title: .RecipeSearch.recipeSearchSuggestionSectionRecent,
      rows: Array(rows)
    )]
  }

  /// Fetched once and matched in memory: the list is small and does not change between
  /// keystrokes, so a request per keystroke would be traffic for nothing.
  ///
  /// The latch is set only on success. A `try?` here would turn the cancellation that every
  /// keystroke causes into a permanently empty list, and no later keystroke would ever match
  /// a category again.
  ///
  /// A real failure is absorbed so the recipe matches still carry the list; only cancellation
  /// reaches the caller, where the generation guard decides what to paint.
  func loadCategoriesIfNeeded() async throws {
    guard !hasLoadedCategories else { return }

    do {
      categories = try await recipeService.getCategories()
      hasLoadedCategories = true
    } catch {
      guard !error.isCancellation else { throw error }
    }
  }

  func matchSections(for recipes: [RecipeSummary]) -> [RecipeSuggestionSectionViewModel] {
    var matched: [RecipeSuggestionSectionViewModel] = []

    let matchedCategories = categories.filter {
      $0.name.localizedCaseInsensitiveContains(text)
    }

    if !matchedCategories.isEmpty {
      matched.append(RecipeSuggestionSectionViewModel(
        id: "categories",
        title: .RecipeSearch.recipeSearchSuggestionSectionCategories,
        rows: matchedCategories.map { RecipeSuggestionRowViewModel(suggestion: .category($0)) }
      ))
    }

    if !recipes.isEmpty {
      matched.append(RecipeSuggestionSectionViewModel(
        id: "recipes",
        title: .RecipeSearch.recipeSearchSuggestionSectionRecipes,
        rows: recipes
          .prefix(recipeLimit)
          .map { RecipeSuggestionRowViewModel(suggestion: .recipe($0)) }
      ))
    }

    return matched
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchInputViewModel {
  var recentLimit: Int {
    4
  }

  var recipeLimit: Int {
    8
  }

  var suggestionPage: Page {
    Page(
      index: 1,
      size: 8
    )
  }
}
