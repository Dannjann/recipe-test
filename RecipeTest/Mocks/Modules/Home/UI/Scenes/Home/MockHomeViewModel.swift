//
//  MockHomeViewModel.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

@Observable
final class MockHomeViewModel: HomeViewModelProtocol {
  var latestRecipes: SectionState<[RecipeSummary]>
  var categories: SectionState<[RecipeCategory]>

  init(
    latestRecipes: SectionState<[RecipeSummary]> = .loading,
    categories: SectionState<[RecipeCategory]> = .loading
  ) {
    self.latestRecipes = latestRecipes
    self.categories = categories
  }

  func loadContent() async {}

  func loadLatestRecipes() async {}

  func loadCategories() async {}
}

// MARK: - Scenarios

extension MockHomeViewModel {
  static func loaded() -> MockHomeViewModel {
    MockHomeViewModel(
      latestRecipes: .loaded(sampleRecipes),
      categories: .loaded(sampleCategories)
    )
  }

  static func loading() -> MockHomeViewModel {
    MockHomeViewModel(
      latestRecipes: .loading,
      categories: .loading
    )
  }

  static func recipesFailed() -> MockHomeViewModel {
    MockHomeViewModel(
      latestRecipes: .failed("The Internet connection appears to be offline."),
      categories: .loaded(sampleCategories)
    )
  }

  static func empty() -> MockHomeViewModel {
    MockHomeViewModel(
      latestRecipes: .empty,
      categories: .empty
    )
  }
}

// MARK: - Getters

extension MockHomeViewModel {
  static var sampleRecipes: [RecipeSummary] {
    [
      .dummy(
        id: "rcp-001",
        title: "Chicken Adobo",
        heroImageURL: nil
      ),
      .dummy(
        id: "rcp-002",
        title: "Pavlova",
        heroImageURL: nil
      ),
      .dummy(
        id: "rcp-003",
        title: "Gỏi Cuốn",
        heroImageURL: nil
      ),
      .dummy(
        id: "rcp-004",
        title: "Pão de Queijo",
        heroImageURL: nil
      ),
      .dummy(
        id: "rcp-005",
        title: "Pad Thai",
        heroImageURL: nil
      ),
      .dummy(
        id: "rcp-006",
        title: "Leche Flan",
        heroImageURL: nil
      ),
    ]
  }

  static var sampleCategories: [RecipeCategory] {
    [
      .dummy(
        id: "cat-01",
        name: "Meal",
        imageURL: nil
      ),
      .dummy(
        id: "cat-02",
        name: "Rice",
        imageURL: nil
      ),
      .dummy(
        id: "cat-03",
        name: "Snacks",
        imageURL: nil
      ),
      .dummy(
        id: "cat-04",
        name: "Desserts",
        imageURL: nil
      ),
      .dummy(
        id: "cat-05",
        name: "Vegan",
        imageURL: nil
      ),
      .dummy(
        id: "cat-06",
        name: "Pasta",
        imageURL: nil
      ),
    ]
  }
}
