//
//  Duration+CookingTime.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Duration {
  /// "25 min", "1 hr 25 min" — units localize themselves rather than coming from a catalog.
  static func cookingTimeText(totalMinutes: Int?) -> String? {
    guard let totalMinutes else { return nil }

    return Duration
      .seconds(totalMinutes * secondsPerMinute)
      .formatted(.units(
        allowed: [.hours, .minutes],
        width: .abbreviated
      ))
  }
}

// MARK: - Getters > Constants

private nonisolated extension Duration {
  static var secondsPerMinute: Int {
    60
  }
}
