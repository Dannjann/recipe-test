//
//  RecipeSummaryMapper.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Turns a `RemoteRecipeSummary` into a `RecipeSummary`.
///
/// The only place both the wire's shape and the app's shape are visible. Returning nil
/// is how a row says it is not usable; the service `compactMap`s, so one bad row costs
/// itself and not the page around it.
nonisolated enum RecipeSummaryMapper {
  /// Requires `id` and `title`. Everything else has a fallback — a row that carries only
  /// those two still renders.
  static func toDomain(from remote: RemoteRecipeSummary) -> RecipeSummary? {
    guard
      let id = remote.id, !id.isEmpty,
      let title = remote.title, !title.isEmpty
    else {
      return nil
    }

    return RecipeSummary(
      id: id,
      title: title,
      shortDescription: remote.shortDescription ?? "",
      heroImageURL: remote.heroImageUrl.flatMap { URL(string: $0) },
      totalTimeMinutes: remote.totalTimeMinutes,
      difficulty: remote.difficulty.flatMap { RecipeDifficulty(rawValue: $0) },
      rating: remote.rating ?? 0,
      ratingCount: remote.ratingCount ?? 0,
      tags: remote.tags ?? []
    )
  }
}
