//
//  RecipeListViewMode.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// How the results are laid out. Screen-local and not persisted — leaving the list forgets it.
nonisolated enum RecipeListViewMode: Hashable, CaseIterable {
  case grid
  case list
}
