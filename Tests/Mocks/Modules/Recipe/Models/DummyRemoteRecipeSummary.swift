//
//  DummyRemoteRecipeSummary.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemoteRecipeSummary {
  static func dummy(
    id: String? = "rcp-001",
    slug: String? = "spaghetti-alla-carbonara",
    title: String? = "Spaghetti alla Carbonara",
    shortDescription: String? = "Roman pasta bound with egg yolk and pecorino.",
    heroImageUrl: String? = "https://api.example.com/api/v1/images/carbonara.png",
    totalTimeMinutes: Int? = 25,
    difficulty: String? = "medium",
    rating: Double? = 4.8,
    ratingCount: Int? = 2147,
    tags: [String]? = ["quick", "classic"]
  ) -> RemoteRecipeSummary {
    RemoteRecipeSummary(
      id: id,
      slug: slug,
      title: title,
      shortDescription: shortDescription,
      heroImageUrl: heroImageUrl,
      totalTimeMinutes: totalTimeMinutes,
      difficulty: difficulty,
      rating: rating,
      ratingCount: ratingCount,
      tags: tags
    )
  }
}
