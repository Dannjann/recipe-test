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
  private(set) var latestRecipes: SectionState<[RecipeSummary]> = .loading
  private(set) var categories: SectionState<[RecipeCategory]> = .loading

  private var latestRecipesGeneration = 0
  private var categoriesGeneration = 0

  private let recipeService: RecipeServiceProtocol

  init(recipeService: RecipeServiceProtocol) {
    self.recipeService = recipeService
  }
}

// MARK: - Getters

private extension HomeViewModel {
  /// The prototype's carousel length. A teaser, not a page: nothing here paginates.
  var latestRecipesPageSize: Int {
    6
  }

  var genericFailureText: String {
    String(localized: .Shared.sharedErrorSomethingWentWrong)
  }
}

// MARK: - Inputs

extension HomeViewModel {
  func loadContent() async {
    async let recipesLoad: Void = loadLatestRecipes()
    async let categoriesLoad: Void = loadCategories()

    _ = await (recipesLoad, categoriesLoad)
  }

  func loadLatestRecipes() async {
    latestRecipesGeneration += 1
    let generation = latestRecipesGeneration
    let previous = latestRecipes
    latestRecipes = refreshing(previous)

    do {
      let page = try await recipeService.getRecipes(
        query: RecipeQuery(sort: .latest),
        page: Page(
          index: 1,
          size: latestRecipesPageSize
        )
      )

      guard generation == latestRecipesGeneration else { return }

      latestRecipes = state(for: page.recipes)
    } catch {
      guard generation == latestRecipesGeneration else { return }

      latestRecipes = state(
        for: error,
        keeping: previous
      )
    }
  }

  func loadCategories() async {
    categoriesGeneration += 1
    let generation = categoriesGeneration
    let previous = categories
    categories = refreshing(previous)

    do {
      let loaded = try await recipeService.getCategories()

      guard generation == categoriesGeneration else { return }

      categories = state(for: loaded)
    } catch {
      guard generation == categoriesGeneration else { return }

      categories = state(
        for: error,
        keeping: previous
      )
    }
  }
}

// MARK: - Helpers

private extension HomeViewModel {
  /// A refresh keeps its content; only a section with nothing to show becomes a spinner.
  func refreshing<Value>(_ current: SectionState<Value>) -> SectionState<Value> {
    current.isLoaded ? current : .loading
  }

  func state<Value: Collection & Equatable>(for value: Value) -> SectionState<Value> {
    value.isEmpty ? .empty : .loaded(value)
  }

  /// SwiftUI cancels `.task` on disappear; that must not paint an error, and must not strand
  /// the section on the spinner `refreshing` just put there either.
  func state<Value>(
    for error: any Error,
    keeping previous: SectionState<Value>
  ) -> SectionState<Value> {
    guard !error.isCancellation else { return previous }

    return .failed(failureDetail(for: error))
  }

  /// `AppError.unknown` describes itself with the generic heading, so passing it on as a detail
  /// would print the same sentence twice.
  func failureDetail(for error: any Error) -> String? {
    let description = error.localizedDescription

    guard description != genericFailureText else { return nil }

    return description
  }
}
