//
//  RecipeDetailViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@MainActor
protocol RecipeDetailViewModelProtocol: AnyObject, Observable {
  var summary: RecipeSummary { get }
  var detail: SectionState<Recipe> { get }
  var checkedIngredientIDs: Set<String> { get }

  var title: String { get }
  var totalTimeMinutes: Int? { get }
  var servings: Int? { get }
  var difficulty: RecipeDifficulty? { get }
  var galleryURLs: [URL] { get }

  func loadDetail() async
  func toggleIngredient(id: String)
}
