//
//  RecipeListLoadState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated enum RecipeListLoadState: Equatable {
  case idle
  case loading
  case loaded
  case failed(String)
}
