//
//  HomeViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What `HomeView` reads and calls.
///
/// Inputs are the three `load*` methods, outputs the two section states — the MVVM shape
/// the team standards ask for. The protocol is what lets a preview drive the screen into
/// any state without a service behind it.
@MainActor
protocol HomeViewModelProtocol {
  var latestRecipes: SectionState<[RecipeSummary]> { get }
  var categories: SectionState<[RecipeCategory]> { get }

  func loadContent() async
  func loadLatestRecipes() async
  func loadCategories() async
}
