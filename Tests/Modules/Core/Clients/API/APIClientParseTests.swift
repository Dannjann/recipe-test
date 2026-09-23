//
//  APIClientParseTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation
@testable import RecipeTest
import Testing

/// Covers which of the two status layers — the HTTP response and the JSON envelope —
/// decides whether a request failed. Both had defects that resolved to `.success`.
struct APIClientParseTests {
  @Test
  func parse_ofA200WithAnEnvelopeSuccess_succeeds() throws {
    let sut = try #require(successValue(of: makeSUT(status: 200, json: #"{"http_status":200,"data":{"id":1}}"#)))

    #expect(sut.statusCode == .ok)
    #expect(sut.data != nil)
  }

  /// The envelope reports the failure while the transport says 200. Reading only the
  /// transport — which almost every response has — handed this back as a success.
  @Test
  func parse_ofA200CarryingAnEnvelopeError_failsWithTheEnvelopeStatus() throws {
    let json = #"{"http_status":422,"message":"The title field is required.","errors":{}}"#
    let sut = makeSUT(status: 200, json: json)

    let info = try #require(failedRequestInfo(of: sut))
    #expect(info.status == .unprocessableEntity)
    #expect(info.message == "The title field is required.")
  }

  /// 419 has no case in `HTTPStatusCode`. It used to map to `nil`, which read exactly
  /// like "this response carried no status", so the body was accepted as a success.
  @Test
  func parse_ofAnUnlistedClientErrorStatus_stillFails() throws {
    let sut = makeSUT(status: 419, json: #"{"data":{}}"#)

    let info = try #require(failedRequestInfo(of: sut))
    #expect(info.status.isRequestError)
  }

  @Test
  func parse_ofAnUnlistedServerErrorStatus_stillFails() throws {
    let sut = makeSUT(status: 521, json: #"{"data":{}}"#)

    let info = try #require(failedRequestInfo(of: sut))
    #expect(info.status.isServerError)
  }

  /// A gateway answering 502 with an HTML page. The decode failure used to surface as a
  /// `DecodingError`, losing the status — the one useful thing that response carried.
  @Test
  func parse_ofAFailingStatusWithANonJSONBody_reportsTheStatusNotADecodingError() throws {
    let sut = makeSUT(status: 502, body: Data("<html><body>Bad Gateway</body></html>".utf8))

    let info = try #require(failedRequestInfo(of: sut))
    #expect(info.status == .badGateway)
  }

  /// The same non-JSON body behind a 200 is a genuine parse failure and must stay one.
  @Test
  func parse_ofASucceedingStatusWithANonJSONBody_stillReportsTheDecodingFailure() {
    let sut = makeSUT(status: 200, body: Data("<html><body>hello</body></html>".utf8))

    guard case let .failure(error) = sut else {
      Issue.record("Expected a failure for an undecodable 200 body.")
      return
    }

    #expect(error is DecodingError)
  }

  @Test
  func parse_ofA204_succeedsWithoutDecodingABody() throws {
    let sut = try #require(successValue(of: makeSUT(status: 204, body: Data())))

    #expect(sut.statusCode == .noContent)
    #expect(sut.data == nil)
  }

  /// No `http_status` in the body: the transport is then the only source of truth, and a
  /// plain-JSON backend still has to parse.
  @Test
  func parse_ofABodyWithoutAnEnvelopeStatus_takesTheStatusFromTheTransport() throws {
    let sut = try #require(successValue(of: makeSUT(status: 201, json: #"{"data":{"id":1}}"#)))

    #expect(sut.statusCode == .created)
    #expect(!sut.carriesEnvelopeStatus)
  }

  @Test
  func parse_ofAFailingStatusWithNoBodyAtAll_reportsTheStatus() throws {
    let sut = makeSUT(status: 500, body: nil)

    let info = try #require(failedRequestInfo(of: sut))
    #expect(info.status == .internalServerError)
  }
}

// MARK: - Helpers

private extension APIClientParseTests {
  func makeSUT(status: Int, json: String) -> Result<APIResponse, any Error> {
    makeSUT(status: status, body: Data(json.utf8))
  }

  func makeSUT(status: Int, body: Data?) -> Result<APIResponse, any Error> {
    let url = URL(string: "https://example.test/v1/recipes")!
    let httpResponse = HTTPURLResponse(
      url: url,
      statusCode: status,
      httpVersion: "HTTP/1.1",
      headerFields: nil
    )

    let response = AFDataResponse<Data>(
      request: nil,
      response: httpResponse,
      data: body,
      metrics: nil,
      serializationDuration: 0,
      result: .success(body ?? Data())
    )

    return DataRequest.parse(response)
  }

  func successValue(of result: Result<APIResponse, any Error>) -> APIResponse? {
    guard case let .success(response) = result else { return nil }

    return response
  }

  func failedRequestInfo(of result: Result<APIResponse, any Error>) -> APIClientFailedRequestInfoType? {
    guard
      case let .failure(error) = result,
      case let APIClientError.failedRequest(info) = error
    else { return nil }

    return info
  }
}

// MARK: - HTTPStatusCode

struct HTTPStatusCodeNearestToTests {
  @Test
  func init_withAListedStatus_usesThatExactCase() {
    #expect(HTTPStatusCode(nearestTo: 422) == .unprocessableEntity)
    #expect(HTTPStatusCode(nearestTo: 204) == .noContent)
  }

  @Test(arguments: [
    // raw, expected classification
    (419, HTTPStatusCode.Classification.requestError),
    (425, HTTPStatusCode.Classification.requestError),
    (520, HTTPStatusCode.Classification.serverError),
    (524, HTTPStatusCode.Classification.serverError),
    (299, HTTPStatusCode.Classification.success),
  ])
  func init_withAnUnlistedStatus_classifiesItByItsRange(
    raw: Int,
    expected: HTTPStatusCode.Classification
  ) throws {
    let sut = try #require(HTTPStatusCode(nearestTo: raw))

    #expect(sut.classification == expected)
  }

  @Test(arguments: [0, 99, 600, 999])
  func init_withAValueThatIsNotAnHTTPStatus_returnsNil(raw: Int) {
    #expect(HTTPStatusCode(nearestTo: raw) == nil)
  }
}
