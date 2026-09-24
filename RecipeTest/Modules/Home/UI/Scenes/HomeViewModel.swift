//
//  HomeViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@Observable
final class HomeViewModel: HomeViewModelProtocol {
  /// The prototype's carousel length. A teaser, not a page — "see all" belongs to the
  /// list screen a later stage adds, so nothing here paginates.
  static let latestRecipesPageSize = 6

  private(set) var latestRecipes: SectionState<[RecipeSummary]> = .loading
  private(set) var categories: SectionState<[RecipeCategory]> = .loading

  private let recipeService: RecipeServiceProtocol

  init(recipeService: RecipeServiceProtocol = AppContainer.shared.recipeService) {
    self.recipeService = recipeService
  }
}

// MARK: - Inputs

extension HomeViewModel {
  /// Both sections at once, and neither can cancel the other: the two `await`s sit in
  /// their own `do`/`catch` inside the methods below, so a thrown error never leaves this
  /// scope.
  func loadContent() async {
    async let recipes: Void = loadLatestRecipes()
    async let categories: Void = loadCategories()

    _ = await (recipes, categories)
  }

  func loadLatestRecipes() async {
    latestRecipes = refreshing(latestRecipes)

    do {
      let page = try await recipeService.getRecipes(
        query: RecipeQuery(sort: .latest),
        page: Page(index: 1, size: Self.latestRecipesPageSize)
      )

      latestRecipes = state(for: page.recipes)
    } catch {
      latestRecipes = state(for: error, keeping: latestRecipes)
    }
  }

  func loadCategories() async {
    categories = refreshing(categories)

    do {
      categories = try await state(for: recipeService.getCategories())
    } catch {
      categories = state(for: error, keeping: categories)
    }
  }
}

// MARK: - Helpers

private extension HomeViewModel {
  /// A refresh keeps what is already on screen. Only a section with nothing to show
  /// becomes a spinner — which is also what makes Retry clear a stale error message.
  func refreshing<Value>(_ current: SectionState<Value>) -> SectionState<Value> {
    current.isLoaded ? current : .loading
  }

  /// Zero rows is `.empty`, never `.loaded([])` — the two have different copy, and a view
  /// that has to ask `isEmpty` is deciding something this type already decided.
  func state<Value: Collection & Equatable>(for value: Value) -> SectionState<Value> {
    value.isEmpty ? .empty : .loaded(value)
  }

  /// Cancellation is not a failure. SwiftUI cancels a `.task` every time the view
  /// disappears, and painting "cancelled" across a section the reader is walking away
  /// from — then leaving it there when they come back — is worse than showing nothing
  /// new.
  func state<Value>(for error: any Error, keeping current: SectionState<Value>) -> SectionState<Value> {
    guard !isCancellation(error) else { return current }

    let description = error.localizedDescription

    return .failed(description.isEmpty ? String(localized: .Shared.sharedErrorSomethingWentWrong) : description)
  }

  func isCancellation(_ error: any Error) -> Bool {
    error is CancellationError || (error as? URLError)?.code == .cancelled
  }
}
