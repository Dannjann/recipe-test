//
//  DummyRecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  /// In the app target, not `Tests/`, because a SwiftUI preview cannot import the test target.
  nonisolated extension RecipeSummary {
    static func dummy(
      id: String = "rcp-001",
      title: String = "Spaghetti alla Carbonara",
      shortDescription: String = "Roman pasta bound with egg yolk and pecorino — never cream.",
      heroImageURL: URL? = URL(string: "https://api.example.com/api/v1/images/carbonara.png"),
      totalTimeMinutes: Int? = 25,
      difficulty: RecipeDifficulty? = .medium,
      rating: Double = 4.8,
      ratingCount: Int = 2147,
      tags: [String] = ["quick", "classic"]
    ) -> Self {
      RecipeSummary(
        id: id,
        title: title,
        shortDescription: shortDescription,
        heroImageURL: heroImageURL,
        totalTimeMinutes: totalTimeMinutes,
        difficulty: difficulty,
        rating: rating,
        ratingCount: ratingCount,
        tags: tags
      )
    }

    /// Six rows with distinct titles and hero URLs, so a grid preview shows variety rather than the same card six times.
    static func dummyList(count: Int = 6) -> [Self] {
      let titles = [
        "Spaghetti alla Carbonara",
        "Miso-Glazed Aubergine",
        "Shakshuka with Feta",
        "Lemon and Herb Roast Chicken",
        "Black Bean and Sweetcorn Tacos",
        "Dark Chocolate and Olive Oil Cake",
      ]

      return (0 ..< count).map { index in
        .dummy(
          id: String(format: "rcp-%03d", index + 1),
          title: titles[index % titles.count],
          heroImageURL: URL(string: "https://api.example.com/api/v1/images/dummy-\(index).png")
        )
      }
    }
  }

#endif
