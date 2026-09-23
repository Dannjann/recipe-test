//
//  PaginationTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct PageTests {
  @Test
  func init_defaultsToTheFirstPage() {
    let sut = makeSUT()

    #expect(sut.index == 1)
    #expect(sut.size == 10)
  }

  @Test
  func next_advancesTheIndexAndKeepsTheSize() {
    let sut = makeSUT().next

    #expect(sut.index == 2)
    #expect(sut.size == 10)
    #expect(sut.next.index == 3)
  }
}

struct RemotePaginationMetaInfoTests {
  @Test
  func decoding_fromAPIJSON_mapsSnakeCaseKeys() throws {
    let sut = try RemotePaginationMetaInfo.decode(makeJSON())

    #expect(sut.total == 25)
    #expect(sut.perPage == 10)
    #expect(sut.currentPage == 1)
    #expect(sut.lastPage == 3)
  }

  @Test(arguments: [
    // total, perPage, currentPage, lastPage, expected
    (25, 10, 1, 3, false),
    (25, 10, 3, 3, true),
    (5, 10, 1, 1, true),
    (10, 10, 1, 1, true),
    // A page past the end: the server answers with the page that was asked for and an
    // empty slice. `== lastPage` reported more to load, so a pager kept asking.
    (25, 10, 4, 3, true),
    (25, 10, 99, 3, true),
  ])
  func hasLoadedAllData_reflectsTheCurrentAndLastPage(
    total: Int,
    perPage: Int,
    currentPage: Int,
    lastPage: Int,
    expected: Bool
  ) {
    let sut = makeSUT(
      total: total,
      perPage: perPage,
      currentPage: currentPage,
      lastPage: lastPage
    )

    #expect(sut.hasLoadedAllData == expected)
  }
}

// MARK: - Helpers

private extension PageTests {
  func makeSUT(size: Int = 10) -> Page {
    Page(size: size)
  }
}

private extension RemotePaginationMetaInfoTests {
  func makeSUT(
    total: Int = 25,
    perPage: Int = 10,
    from: Int? = nil,
    to: Int? = nil,
    currentPage: Int = 1,
    lastPage: Int = 3
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

  func makeJSON() -> Data {
    Data("""
    {
      "total": 25,
      "per_page": 10,
      "from": 1,
      "to": 10,
      "current_page": 1,
      "last_page": 3
    }
    """.utf8)
  }
}
