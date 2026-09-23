//
//  RecipeListPage.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// One page of the recipe list.
///
/// The pagination meta is carried through rather than flattened into a couple of `Int`s,
/// so a pager gets `hasLoadedAllData` without the service having to re-derive it.
nonisolated struct RecipeListPage: Equatable {
  let recipes: [RecipeSummary]
  let meta: PaginationMetaInfo
}

// MARK: - Getters

nonisolated extension RecipeListPage {
  /// Forwarded so a pager reads it off the page it was just handed, rather than reaching
  /// into the meta block itself.
  var hasLoadedAllData: Bool {
    meta.hasLoadedAllData
  }
}
