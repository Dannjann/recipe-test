//
//  APIClientModelDecodingTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct APIClientModelDecodingTests {
  /// A stand-in remote model. `display_name` proves the snake_case decoder is the one
  /// being used.
  struct Item: APIModel, Decodable, Equatable {
    let id: String?
    let displayName: String?
  }

  @Test
  func decodeModel_decodesTheDataPayload() throws {
    let sut = makeSUT()
    let response = try makeResponse(data: #"{"id": "1", "display_name": "First"}"#)

    let item: Item = try sut.decodeModel(response)

    #expect(item == Item(id: "1", displayName: "First"))
  }

  @Test
  func decodeModel_decodesAnArrayPayload() throws {
    let sut = makeSUT()
    let response = try makeResponse(data: #"[{"id": "1"}, {"id": "2"}]"#)

    let items: [Item] = try sut.decodeModel(response)

    #expect(items.map(\.id) == ["1", "2"])
  }

  @Test
  func decodeModel_withNoData_throwsAndReportsTheError() throws {
    let recorder = ErrorRecorder()
    let sut = makeSUT(onError: recorder.record)
    let response = try makeResponse(data: "null")

    #expect(throws: APIClientError.self) {
      let _: Item = try sut.decodeModel(response)
    }

    #expect(recorder.count == 1)
  }

  @Test
  func decodeModelWithMeta_decodesBothPayloadAndMeta() throws {
    let sut = makeSUT()
    let response = try makeResponse(
      data: #"[{"id": "1"}]"#,
      meta: #"{"total": 25, "per_page": 10, "from": 1, "to": 10, "current_page": 1, "last_page": 3}"#
    )

    let (items, meta): ([Item], RemotePaginationMetaInfo) = try sut.decodeModelWithMeta(response)

    #expect(items.map(\.id) == ["1"])
    #expect(meta.total == 25)
    #expect(meta.lastPage == 3)
  }

  @Test
  func decodeModelWithMeta_withNoMeta_throwsAndReportsTheError() throws {
    let recorder = ErrorRecorder()
    let sut = makeSUT(onError: recorder.record)
    let response = try makeResponse(data: #"[{"id": "1"}]"#)

    #expect(throws: APIClientError.self) {
      let _: ([Item], RemotePaginationMetaInfo) = try sut.decodeModelWithMeta(response)
    }

    #expect(recorder.count == 1)
  }
}

// MARK: - Helpers

private extension APIClientModelDecodingTests {
  func makeSUT(onError: @escaping SendableErrorResult = { _ in }) -> APIClient {
    APIClient(
      baseURL: URL(string: "https://api.example.com/api")!,
      version: "v1",
      onError: onError
    )
  }

  func makeResponse(data: String, meta: String? = nil) throws -> APIResponse {
    var json = #"{"http_status": 200, "message": "OK", "data": \#(data)"#

    if let meta {
      json += #", "meta": \#(meta)"#
    }

    json += "}"

    return try JSONDecoder().decode(APIResponse.self, from: Data(json.utf8))
  }
}
