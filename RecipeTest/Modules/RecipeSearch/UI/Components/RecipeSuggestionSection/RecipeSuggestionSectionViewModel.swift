//
//  RecipeSuggestionSectionViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RecipeSuggestionSectionViewModel: Identifiable, Equatable {
  let id: String
  let title: LocalizedStringResource?
  let rows: [RecipeSuggestionRowViewModel]
}
