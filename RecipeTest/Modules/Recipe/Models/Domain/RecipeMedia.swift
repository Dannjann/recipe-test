//
//  RecipeMedia.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A gallery photograph. `url` is non-optional — an image with nowhere to load from is
/// not a gallery entry, so the mapper drops it rather than carrying an empty slot.
nonisolated struct RecipeMedia: Equatable, Identifiable {
  let id: String
  let url: URL
  let altText: String?
}
