//
//  DummyRecipe.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG
  nonisolated extension Recipe {
    static func dummy(
      id: String = "rcp-001",
      title: String = "Spaghetti alla Carbonara",
      description: String = "Roman pasta bound with egg yolk and pecorino — never cream.",
      heroImageURL: URL? = URL(string: "https://example.com/carbonara.jpg"),
      category: String? = "Pasta",
      cuisine: String? = "italian",
      mealType: String? = "dinner",
      totalTimeMinutes: Int? = 25,
      servings: Int? = 4,
      difficulty: RecipeDifficulty? = .medium,
      isVegetarian: Bool = false,
      gallery: [URL] = [
        URL(string: "https://example.com/carbonara.jpg"),
        URL(string: "https://example.com/carbonara-2.jpg"),
        URL(string: "https://example.com/carbonara-3.jpg"),
      ].compactMap { $0 },
      ingredients: [RecipeIngredient] = RecipeIngredient.dummyList(),
      steps: [String] = [
        "Bring a large pan of well-salted water to the boil and drop in the spaghetti.",
        "Dice the bacon and fry it gently until the fat runs and the edges crisp.",
        "Beat the egg yolks with the grated pecorino and a great deal of black pepper.",
        "Drain the pasta, keeping a cup of its water, and tip it into the bacon pan.",
        "Off the heat, stir through the egg mixture, loosening with pasta water.",
      ]
    ) -> Recipe {
      Recipe(
        id: id,
        title: title,
        description: description,
        heroImageURL: heroImageURL,
        category: category,
        cuisine: cuisine,
        mealType: mealType,
        totalTimeMinutes: totalTimeMinutes,
        servings: servings,
        difficulty: difficulty,
        isVegetarian: isVegetarian,
        gallery: gallery,
        ingredients: ingredients,
        steps: steps
      )
    }
  }

  nonisolated extension RecipeIngredient {
    static func dummy(
      id: String = "rcp-001-0",
      quantityText: String = "320 g",
      name: String = "Spaghetti",
      imageURL: URL? = nil,
      isMain: Bool = true
    ) -> RecipeIngredient {
      RecipeIngredient(
        id: id,
        quantityText: quantityText,
        name: name,
        imageURL: imageURL,
        isMain: isMain
      )
    }

    /// Four main ingredients and two supporting ones, so a strip and a checklist built
    /// from the same fixture differ the way they do against real data.
    static func dummyList() -> [RecipeIngredient] {
      [
        .dummy(
          id: "rcp-001-0",
          quantityText: "320 g",
          name: "Spaghetti"
        ),
        .dummy(
          id: "rcp-001-1",
          quantityText: "6",
          name: "Egg Yolks"
        ),
        .dummy(
          id: "rcp-001-2",
          quantityText: "150 g",
          name: "Bacon"
        ),
        .dummy(
          id: "rcp-001-3",
          quantityText: "50 g",
          name: "Pecorino"
        ),
        .dummy(
          id: "rcp-001-4",
          quantityText: "to taste",
          name: "Salt",
          isMain: false
        ),
        .dummy(
          id: "rcp-001-5",
          quantityText: "to taste",
          name: "Black Pepper",
          isMain: false
        ),
      ]
    }
  }
#endif
