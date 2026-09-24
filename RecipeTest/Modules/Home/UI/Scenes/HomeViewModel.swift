//
//  HomeViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation

@Observable
final class HomeViewModel: HomeViewModelProtocol {
  /// The prototype's carousel length. A teaser, not a page — "see all" belongs to the
  /// list screen a later stage adds, so nothing here paginates.
  static let latestRecipesPageSize = 6

  private(set) var latestRecipes: SectionState<[RecipeSummary]> = .loading
  private(set) var categories: SectionState<[RecipeCategory]> = .loading

  /// Bumped when a section starts a request, and checked again when that request
  /// answers. Nothing here is serialised: `.task`, `.refreshable` and each Retry button
  /// all call in independently, so without this a slow first request can land after a
  /// faster second one and overwrite fresher content with staler.
  private var latestRecipesGeneration = 0
  private var categoriesGeneration = 0

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
    async let recipesLoad: Void = loadLatestRecipes()
    async let categoriesLoad: Void = loadCategories()

    _ = await (recipesLoad, categoriesLoad)
  }

  func loadLatestRecipes() async {
    latestRecipesGeneration += 1
    let generation = latestRecipesGeneration
    latestRecipes = refreshing(latestRecipes)

    do {
      let page = try await recipeService.getRecipes(
        query: RecipeQuery(sort: .latest),
        page: Page(index: 1, size: Self.latestRecipesPageSize)
      )

      guard generation == latestRecipesGeneration else { return }

      latestRecipes = state(for: page.recipes)
    } catch {
      guard generation == latestRecipesGeneration else { return }

      latestRecipes = state(for: error, keeping: latestRecipes)
    }
  }

  func loadCategories() async {
    categoriesGeneration += 1
    let generation = categoriesGeneration
    categories = refreshing(categories)

    do {
      let loaded = try await recipeService.getCategories()

      guard generation == categoriesGeneration else { return }

      categories = state(for: loaded)
    } catch {
      guard generation == categoriesGeneration else { return }

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

    return .failed(error.localizedDescription)
  }

  /// Four shapes, because the transport is Alamofire: it never surfaces a bare
  /// `URLError`, it wraps one — which is why `APIClient` already has to unwrap
  /// `underlyingError` to recognise a dropped connection. Checking only the two Swift
  /// concurrency shapes would miss every cancellation the network layer actually reports.
  func isCancellation(_ error: any Error) -> Bool {
    if error is CancellationError {
      return true
    }

    if (error as? URLError)?.code == .cancelled {
      return true
    }

    guard let afError = error.asAFError else { return false }

    return afError.isExplicitlyCancelledError
      || (afError.underlyingError as? URLError)?.code == .cancelled
  }
}
