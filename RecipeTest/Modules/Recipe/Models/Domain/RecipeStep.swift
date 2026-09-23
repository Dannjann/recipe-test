//
//  RecipeStep.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One instruction. `number` drives display order — the mapper sorts on it rather than
/// trusting the order the payload arrived in.
nonisolated struct RecipeStep: Equatable, Identifiable {
  let id: String
  let number: Int
  let text: String
  let imageURL: URL?
  let durationSeconds: Int?
}
