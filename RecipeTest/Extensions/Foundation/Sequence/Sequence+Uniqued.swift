//
//  Sequence+Uniqued.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated extension Sequence where Element: Hashable {
  func uniqued() -> [Element] {
    var seen: Set<Element> = []

    return filter { seen.insert($0).inserted }
  }
}
