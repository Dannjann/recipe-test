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
  }

#endif
