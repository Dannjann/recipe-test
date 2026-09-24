//
//  RecipeFixtureTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// Pins the shipped fixtures to the contract the spec defines.
///
/// The DTOs decode whatever they are handed, so a hand-edit that drops a key or invents a
/// category would surface as an empty screen rather than a failing test. This suite is
/// what makes that a test failure instead.
struct RecipeFixtureTests {
  @Test
  func recipes_carryTheContractsKeysAndNothingElse() throws {
    let recipes = try rows("recipes")

    #expect(recipes.count == 36)

    for recipe in recipes {
      #expect(Set(recipe.keys) == Self.topLevelKeys)
      #expect(try Self.categories.contains(#require(recipe["category"] as? String)))
      #expect(try Self.difficulties.contains(#require(recipe["difficulty"] as? String)))
      #expect(recipe["is_vegetarian"] is Bool)
      #expect(try #require(recipe["steps"] as? [String]).isEmpty == false)
      #expect(try #require(recipe["gallery"] as? [String]).count == 3)
    }
  }

  /// `PH_I` covers a fraction of the 370 ingredient names, so most ingredients have no
  /// photograph. The mapper has to cope with that, which means the fixture has to contain
  /// at least one — otherwise the test that proves it is testing nothing.
  @Test
  func ingredients_areFlatAndMayHaveNoPhotograph() throws {
    let recipes = try rows("recipes")
    var sawMissingImage = false

    for recipe in recipes {
      let ingredients = try #require(recipe["ingredients"] as? [[String: Any]])

      #expect(ingredients.isEmpty == false)
      #expect(ingredients.filter { $0["is_main"] as? Bool == true }.count <= 6)

      for ingredient in ingredients {
        #expect(Set(ingredient.keys) == Self.ingredientKeys)
        #expect(try #require(ingredient["name"] as? String).isEmpty == false)
        #expect(ingredient["quantity_text"] is String)

        if ingredient["image_url"] is NSNull {
          sawMissingImage = true
        }
      }
    }

    #expect(sawMissingImage, "the mapper must cope with a null ingredient image")
  }

  /// A reused gallery photograph reads as a broken carousel, not as a design choice.
  @Test
  func images_areAbsoluteAndGalleryPhotographsAreUnique() throws {
    let recipes = try rows("recipes")
    var seen = Set<String>()

    for recipe in recipes {
      let hero = try #require(recipe["hero_image_url"] as? String)
      #expect(URL(string: hero)?.scheme == "https")

      for photo in try #require(recipe["gallery"] as? [String]).dropFirst() {
        #expect(URL(string: photo)?.scheme == "https")
        #expect(seen.insert(photo).inserted, "gallery photograph reused: \(photo)")
      }
    }
  }

  @Test
  func categories_coverEveryRecipeExactlyOnce() throws {
    let recipes = try rows("recipes")
    let categories = try rows("categories")

    #expect(Set(categories.compactMap { $0["name"] as? String }) == Self.categories)

    for category in categories {
      #expect(Set(category.keys) == Self.categoryKeys)

      let name = try #require(category["name"] as? String)
      let expected = recipes.filter { $0["category"] as? String == name }.count

      #expect(category["recipe_count"] as? Int == expected)
    }

    #expect(categories.compactMap { $0["recipe_count"] as? Int }.reduce(0, +) == recipes.count)
  }
}

// MARK: - Contract

private extension RecipeFixtureTests {
  static let topLevelKeys: Set<String> = [
    "id", "title", "description", "category", "cuisine", "meal_type",
    "total_time_minutes", "servings", "difficulty", "is_vegetarian",
    "hero_image_url", "gallery", "ingredients", "steps",
  ]

  static let ingredientKeys: Set<String> = ["quantity_text", "name", "image_url", "is_main"]
  static let categoryKeys: Set<String> = ["id", "name", "image_url", "recipe_count"]
  static let categories: Set<String> = ["Meal", "Rice", "Snacks", "Desserts", "Vegan", "Pasta"]
  static let difficulties: Set<String> = ["easy", "medium", "hard"]
}

// MARK: - Helpers

private extension RecipeFixtureTests {
  /// `.main` is the host app bundle when these run, which is where the fixtures ship —
  /// `Bundle(for:)` on a test-target type would find the test bundle instead. This is the
  /// same bundle `MockAPIRouter` reads by default, so the assertions are against what the
  /// demo build actually serves.
  func rows(_ name: String) throws -> [[String: Any]] {
    let url = try #require(Bundle.main.url(forResource: name, withExtension: "json"))
    let data = try Data(contentsOf: url)

    return try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
  }
}
