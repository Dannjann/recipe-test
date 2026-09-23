//
//  DummyRemotePaginationMetaInfo.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest

extension RemotePaginationMetaInfo {
  static func dummy(
    total: Int = 1,
    perPage: Int = 10,
    from: Int? = 1,
    to: Int? = 1,
    currentPage: Int = 1,
    lastPage: Int = 1
  ) -> RemotePaginationMetaInfo {
    RemotePaginationMetaInfo(
      total: total,
      perPage: perPage,
      from: from,
      to: to,
      currentPage: currentPage,
      lastPage: lastPage
    )
  }
}
