//
//  MockRecipeSearchViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  @Observable
  final class MockRecipeSearchViewModel: RecipeSearchViewModelProtocol {
    var searchText: String
    var clearToken = 0
    var isVegetarian: Bool
    var searchesSteps: Bool
    var servings: RecipeServings?
    var includeIngredients: [String]
    var excludeIngredients: [String]

    init(
      searchText: String = "",
      isVegetarian: Bool = false,
      searchesSteps: Bool = false,
      servings: RecipeServings? = nil,
      includeIngredients: [String] = [],
      excludeIngredients: [String] = []
    ) {
      self.searchText = searchText
      self.isVegetarian = isVegetarian
      self.searchesSteps = searchesSteps
      self.servings = servings
      self.includeIngredients = includeIngredients
      self.excludeIngredients = excludeIngredients
    }
  }

  // MARK: - Getters

  extension MockRecipeSearchViewModel {
    var fieldText: String {
      fieldIsPlaceholder ? "Search recipes or ingredients" : searchText
    }

    var fieldIsPlaceholder: Bool {
      searchText.isEmpty
    }

    var fieldAccessibilityValue: String {
      fieldIsPlaceholder ? "Nothing entered" : searchText
    }

    var showsFieldClear: Bool {
      !fieldIsPlaceholder
    }

    var servingsOptions: [RecipeServingsOptionViewModel] {
      RecipeServings.allCases.map {
        RecipeServingsOptionViewModel(
          servings: $0,
          isSelected: $0 == servings
        )
      }
    }

    var includeChips: [RecipeIngredientChipViewModel] {
      includeIngredients.map {
        RecipeIngredientChipViewModel(
          ingredient: $0,
          kind: .include
        )
      }
    }

    var excludeChips: [RecipeIngredientChipViewModel] {
      excludeIngredients.map {
        RecipeIngredientChipViewModel(
          ingredient: $0,
          kind: .exclude
        )
      }
    }

    var showsClearAll: Bool {
      !fieldIsPlaceholder
        || isVegetarian
        || searchesSteps
        || servings != nil
        || !includeIngredients.isEmpty
        || !excludeIngredients.isEmpty
    }
  }

  // MARK: - Inputs

  extension MockRecipeSearchViewModel {
    func toggleVegetarian() {
      isVegetarian.toggle()
    }

    func toggleSearchesSteps() {
      searchesSteps.toggle()
    }

    func select(servings: RecipeServings) {
      self.servings = self.servings == servings ? nil : servings
    }

    func addInclude(_ text: String) {
      includeIngredients.append(text)
    }

    func addExclude(_ text: String) {
      excludeIngredients.append(text)
    }

    func remove(chip: RecipeIngredientChipViewModel) {
      includeIngredients.removeAll { $0 == chip.ingredient }
      excludeIngredients.removeAll { $0 == chip.ingredient }
    }

    func set(searchText: String) {
      self.searchText = searchText
    }

    func clearAll() {
      searchText = ""
      clearToken += 1
      isVegetarian = false
      searchesSteps = false
      servings = nil
      includeIngredients = []
      excludeIngredients = []
    }

    func apply() -> RecipeSearchResult {
      .apply(.empty)
    }
  }

  // MARK: - Fixtures

  extension MockRecipeSearchViewModel {
    static func empty() -> MockRecipeSearchViewModel {
      MockRecipeSearchViewModel()
    }

    static func filled() -> MockRecipeSearchViewModel {
      MockRecipeSearchViewModel(
        searchText: "adobo",
        isVegetarian: true,
        searchesSteps: true,
        servings: .four,
        includeIngredients: ["garlic", "soy sauce"],
        excludeIngredients: ["pork"]
      )
    }
  }
#endif
