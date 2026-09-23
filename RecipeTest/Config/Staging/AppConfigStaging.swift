//
//  AppConfigStaging.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

struct AppConfigStaging: AppConfigProtocol {
  var baseUrl: String {
    "https://api-staging.example.com"
  }

  var landingPageBaseUrl: String {
    "https://staging.example.com"
  }
}
