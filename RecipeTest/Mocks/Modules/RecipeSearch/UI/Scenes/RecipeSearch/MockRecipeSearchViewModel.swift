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

    var fieldTextColorStyle: Color.ThemeColor {
      fieldIsPlaceholder ? .textTertiary : .textPrimary
    }

    var fieldAccessibilityValue: String {
      fieldIsPlaceholder ? "Nothing entered" : searchText
    }

    var showsFieldClear: Bool {
      !fieldIsPlaceholder
    }

    var servingsOptions: [any RecipeServingsOptionViewModelProtocol] {
      RecipeServings.allCases.map { option -> any RecipeServingsOptionViewModelProtocol in
        guard option == servings else {
          return RecipeServingsOptionViewModel(servings: option)
        }

        return RecipeSelectedServingsOptionViewModel(servings: option)
      }
    }

    var includeChips: [any RecipeIngredientChipViewModelProtocol] {
      includeIngredients.map { RecipeIncludedIngredientChipViewModel(ingredient: $0) }
    }

    var excludeChips: [any RecipeIngredientChipViewModelProtocol] {
      excludeIngredients.map { RecipeExcludedIngredientChipViewModel(ingredient: $0) }
    }

    var showsClearAll: Bool {
      !fieldIsPlaceholder
        || isVegetarian
        || searchesSteps
        || servings != nil
        || !includeIngredients.isEmpty
        || !excludeIngredients.isEmpty
    }

    var result: RecipeSearchResult {
      .apply(.empty)
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

    func removeInclude(_ ingredient: String) {
      includeIngredients.removeAll { $0 == ingredient }
    }

    func removeExclude(_ ingredient: String) {
      excludeIngredients.removeAll { $0 == ingredient }
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

    func recordSearch() {}
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
