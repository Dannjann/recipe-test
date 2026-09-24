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
  var detail: SectionState<Recipe> { get }
  var checkedIngredientIDs: Set<String> { get }

  var title: String { get }
  var descriptionText: String { get }
  var cookingTimeText: String? { get }
  var servingsText: String? { get }
  var difficultyText: LocalizedStringResource? { get }
  var galleryURLs: [URL] { get }

  func loadDetail() async
  func toggleIngredient(id: String)
}
