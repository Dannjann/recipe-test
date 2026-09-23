//
//  APIClient+ModelDecoding.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import Foundation

nonisolated extension APIClient {
  /// Decodes an `APIResponse` into a remote model plus its `meta` block, then maps both
  /// into domain types.
  ///
  /// The mapper is what keeps a change in the API's JSON shape from reaching view models:
  /// it stops at `RemoteItem.asDomain()`.
  func decodeRemoteModelWithMeta<RemoteModel: Decodable, RemoteMetaModel: Decodable, DomainModel, MetaModel>(
    _ apiResponse: APIResponse,
    thenMapUsing mapper: @escaping SingleResultWithReturn<RemoteModel, DomainModel?>,
    metaMapper: @escaping SingleResultWithReturn<RemoteMetaModel, MetaModel?>
  ) throws -> (DomainModel, MetaModel) {
    do {
      guard
        let remoteModel: RemoteModel = try apiResponse.decodedValue(),
        let domainModel = mapper(remoteModel),
        let remoteMetaModel: RemoteMetaModel = try apiResponse.decodeMeta(),
        let metaModel = metaMapper(remoteMetaModel)
      else {
        throw AppError.unknown
      }

      return (domainModel, metaModel)
    } catch {
      onError(error)
      throw error
    }
  }
}
