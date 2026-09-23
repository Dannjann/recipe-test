//
//  APIErrorCode.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2020 Danjan. All rights reserved.
//

import Foundation

nonisolated enum APIErrorCode: String, Codable {
  case httpUnauthorized = "HTTP_UNAUTHORIZED"

  // Add other error codes here with required handling

  case unknown = "UNKNOWN_ERROR"

  static let `default`: APIErrorCode = .unknown
}
