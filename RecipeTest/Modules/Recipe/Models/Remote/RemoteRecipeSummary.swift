//
//  RemoteRecipeSummary.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One row of the recipe list, as the API sends it.
///
/// Every property is optional on purpose: a single missing or retyped field must cost
/// one value, not the whole page. What the app actually requires is decided in
/// `RecipeSummaryMapper`, which is the only place a `nil` here turns into a dropped row.
///
/// Property names are the camelCase of the wire's snake_case — `hero_image_url` becomes
/// `heroImageUrl`, not `heroImageURL`. `APIModel`'s decoder converts the keys, so
/// renaming one of these to a nicer acronym casing would silently decode it as nil.
nonisolated struct RemoteRecipeSummary: APIModel, Decodable, Equatable {
  let id: String?
  let slug: String?
  let title: String?
  let shortDescription: String?
  let heroImageUrl: String?
  let totalTimeMinutes: Int?
  let difficulty: String?
  let rating: Double?
  let ratingCount: Int?
  let tags: [String]?
}
