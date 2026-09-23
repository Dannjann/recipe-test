//
//  APIClient+ModelDecoding.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import Foundation

nonisolated extension APIClient {
  /// Decodes an `APIResponse`'s `data` payload into a remote model.
  ///
  /// Decoding only. Turning a remote model into a domain one is a mapper's job, in the
  /// feature's own `Services` folder — that boundary is what keeps a change in the
  /// API's JSON shape from reaching a view model.
  ///
  /// Every failure is reported through `onError` before it is rethrown, so a decoding
  /// break shows up in monitoring rather than only at the call site.
  func decodeModel<T: Decodable>(_ response: APIResponse) throws -> T {
    do {
      guard let model: T = try response.decodedValue() else {
        throw APIClientError.dataNotFound(T.self)
      }

      return model
    } catch {
      onError(error)
      throw error
    }
  }

  /// Decodes an `APIResponse`'s `data` payload and its `meta` block together.
  ///
  /// A missing `meta` is an error rather than a defaulted value: a caller asking for
  /// meta is paginating, and inventing `currentPage: 1, lastPage: 1` for a response
  /// that carried no pagination would silently stop the pager at the first page.
  func decodeModelWithMeta<T: Decodable, M: Decodable>(_ response: APIResponse) throws -> (T, M) {
    do {
      guard let model: T = try response.decodedValue() else {
        throw APIClientError.dataNotFound(T.self)
      }

      guard let meta: M = try response.decodeMeta() else {
        throw APIClientError.dataNotFound(M.self)
      }

      return (model, meta)
    } catch {
      onError(error)
      throw error
    }
  }
}
