//
//  Page.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2020 Danjan. All rights reserved.
//

import Foundation

nonisolated struct Page: Equatable {
  let index: Int
  let size: Int

  init(
    index: Int = 1,
    size: Int
  ) {
    self.index = index
    self.size = size
  }
}

// MARK: - Getters

nonisolated extension Page {
  var next: Self {
    Page(
      index: index + 1,
      size: size
    )
  }
}
