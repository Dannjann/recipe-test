//
//  RemotePaginationMetaInfo.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RemotePaginationMetaInfo: APIModel, Codable, Equatable {
  var total: Int
  var perPage: Int
  var from: Int?
  var to: Int?
  var currentPage: Int
  var lastPage: Int
}

nonisolated extension RemotePaginationMetaInfo {
  /// `>=`, not `==`: a server asked for a page past the end answers with that page
  /// number and an empty slice rather than an error — `MockAPIRouter.paginate` does
  /// exactly this. With `==`, `total: 25, perPage: 10, currentPage: 4, lastPage: 3`
  /// reports more data to load, and a pager driven off `!hasLoadedAllData` requests
  /// empty pages forever.
  var hasLoadedAllData: Bool {
    total <= perPage || currentPage >= lastPage
  }
}
