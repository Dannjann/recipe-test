//
//  DummyRecipeListPage.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

#if DEBUG

  /// In the app target, not `Tests/`, because a SwiftUI preview cannot import the test target.
  nonisolated extension RecipeListPage {
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
