//
//  HomeViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

@MainActor
protocol HomeViewModelProtocol: AnyObject {
  var latestRecipes: SectionState<[RecipeSummary]> { get }
  var categories: SectionState<[RecipeCategory]> { get }

  func loadContent() async
  func loadLatestRecipes() async
  func loadCategories() async
}
