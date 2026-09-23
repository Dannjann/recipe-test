//
//  APIResponseTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation
@testable import RecipeTest
import Testing

struct APIResponseTests {
  @Test
  func decoding_ofA200Response_carriesDataAndNoErrors() throws {
    let sut = try makeSUT(fixture: "APIResponseTests_200")

    #expect(sut.statusCode == .ok)
    #expect(sut.errors == nil)
    #expect(sut.data != nil)
  }

  @Test
  func decoding_ofA422ResponseWithOneError_carriesTheFieldError() throws {
    let sut = try makeSUT(fixture: "APIResponseTests_422_1")

    #expect(sut.statusCode == .unprocessableEntity)
    #expect(sut.errors?.count == 1)
    #expect(sut.message == "The title field is required.")
  }

  @Test
  func decoding_ofA422ResponseWithTwoErrors_carriesEveryFieldError() throws {
    let sut = try makeSUT(fixture: "APIResponseTests_422_2")

    #expect(sut.statusCode == .unprocessableEntity)
    #expect(sut.errors?.count == 2)
  }

  /// The envelope keys are a convention, not a requirement — a backend returning bare
  /// JSON has no `http_status`, and decoding used to fail outright on its absence.
  @Test
  func decoding_ofABodyWithoutAnEnvelopeStatus_stillSucceeds() throws {
    let sut = try JSONDecoder().decode(APIResponse.self, from: Data(#"{"data":{"id":1}}"#.utf8))

    #expect(!sut.carriesEnvelopeStatus)
    #expect(sut.data != nil)
  }

  @Test
  func decoding_ofABodyWithAnEnvelopeStatus_reportsItAsSuch() throws {
    let sut = try makeSUT(fixture: "APIResponseTests_200")

    #expect(sut.carriesEnvelopeStatus)
    #expect(sut.statusCode == .ok)
  }

  @Test
  func init_withNoContent_isRepresentableWithoutABody() {
    let sut = APIResponse(statusCode: .noContent)

    #expect(sut.statusCode == .noContent)
    #expect(sut.data == nil)
    #expect(sut.errors == nil)
  }
}

struct ResponseEncodingTests {
  @Test
  func detectEncoding_withAUTF8Body_reportsUTF8() {
    let sut = Data(#"{"http_status":200}"#.utf8)

    #expect(DataRequest.detectEncoding(of: sut) == .utf8)
  }

  @Test
  func decoding_ofALatin1Body_succeedsAfterConversionToUTF8() throws {
    let latin1 = try makeLatin1Body()

    // Guard the premise: this really is not valid UTF-8.
    #expect(String(data: latin1, encoding: .utf8) == nil)

    let converted = try #require(String(data: latin1, encoding: .isoLatin1)?.data(using: .utf8))
    let sut = try JSONDecoder().decode(APIResponse.self, from: converted)

    #expect(sut.message == "Café não encontrado")
    #expect(sut.statusCode == .notFound)
  }
}

// MARK: - Helpers

private extension APIResponseTests {
  func makeSUT(fixture: String = "APIResponseTests_200") throws -> APIResponse {
    try Fixture.apiResponse(fixture)
  }
}

private extension ResponseEncodingTests {
  func makeLatin1Body(
    json: String = #"{"message":"Café não encontrado","http_status":404}"#
  ) throws -> Data {
    try #require(json.data(using: .isoLatin1))
  }
}
