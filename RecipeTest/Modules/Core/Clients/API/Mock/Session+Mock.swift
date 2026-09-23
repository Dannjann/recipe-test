//
//  Session+Mock.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Alamofire
import Foundation

nonisolated extension Alamofire.Session {
  /// An Alamofire session whose transport is `MockURLProtocol`.
  ///
  /// Ephemeral so nothing is cached between launches — each run replays the fixture from
  /// scratch, which is what keeps the loading state visible every time.
  static func mocked() -> Alamofire.Session {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]

    return Alamofire.Session(configuration: configuration)
  }
}
