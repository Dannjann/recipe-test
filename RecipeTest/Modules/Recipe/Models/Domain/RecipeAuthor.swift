//
//  RecipeAuthor.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeAuthor: Equatable, Identifiable {
  let id: String
  let name: String
  let avatarURL: URL?
  let profileURL: URL?
}
