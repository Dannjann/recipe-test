//
//  DummyRecipeListPage.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  nonisolated extension RecipeListPage {
    /// Builds a page from ids alone, with the meta a real backend would send alongside
    /// them. `total` and `lastPage` default to "this is the only page".
    static func dummy(
      ids: [String] = ["rcp-001", "rcp-002", "rcp-003"],
      total: Int? = nil,
      perPage: Int = 10,
      currentPage: Int = 1,
      lastPage: Int = 1
    ) -> Self {
      RecipeListPage(
        recipes: ids.map { RecipeSummary.dummy(id: $0, title: "Recipe \($0)") },
        meta: PaginationMetaInfo(
          total: total ?? ids.count,
          perPage: perPage,
          from: ids.isEmpty ? nil : (currentPage - 1) * perPage + 1,
          to: ids.isEmpty ? nil : (currentPage - 1) * perPage + ids.count,
          currentPage: currentPage,
          lastPage: lastPage
        )
      )
    }
  }

#endif
