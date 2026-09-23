//
//  RecipeNutrition.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Every figure is optional: the API sends the block or omits it, and a partial block
/// is a real shape — a recipe can carry calories without a fibre figure.
nonisolated struct RecipeNutrition: Equatable {
  let caloriesPerServing: Int?
  let proteinGrams: Double?
  let carbohydrateGrams: Double?
  let fatGrams: Double?
  let fibreGrams: Double?
  let sodiumMilligrams: Double?
}
