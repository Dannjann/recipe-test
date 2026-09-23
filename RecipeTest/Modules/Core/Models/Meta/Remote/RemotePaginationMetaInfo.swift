//
//  RemotePaginationMetaInfo.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation

nonisolated struct RemotePaginationMetaInfo: APIModel, Codable {
  var total: Int
  var perPage: Int
  var from: Int?
  var to: Int?
  var currentPage: Int
  var lastPage: Int
}

nonisolated extension RemotePaginationMetaInfo {
  var hasLoadedAllData: Bool {
    total <= perPage || currentPage == lastPage
  }
}
