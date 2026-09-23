//
//  AppConfig.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

protocol AppConfigProtocol {
  // MARK: Backend

  var baseUrl: String { get }
  var landingPageBaseUrl: String { get }
  var apiUrl: String { get }
  var apiVersion: String { get }
  var privacyPolicyUrl: String { get }
  var termsOfServiceUrl: String { get }

  // MARK: Defaults

  var defaultPageSize: Int { get }

  // MARK: Mocking

  /// When true, requests are answered from bundled JSON instead of the network.
  /// Set to false to run against `baseUrl` for real — nothing else needs to change.
  var usesMockAPI: Bool { get }
}

// MARK: - Default values

extension AppConfigProtocol {
  var apiUrl: String {
    "\(baseUrl)/api"
  }

  var apiVersion: String {
    "v1"
  }

  var apiUrlWithVersion: String {
    "\(apiUrl)/\(apiVersion)"
  }

  var privacyPolicyUrl: String {
    "\(landingPageBaseUrl)/privacy-policy"
  }

  var termsOfServiceUrl: String {
    "\(landingPageBaseUrl)/terms-of-service"
  }

  var defaultPageSize: Int {
    10
  }

  /// This project is a demo: there is no backend behind `baseUrl`, so every request is
  /// served by `MockURLProtocol` from `Resources/MockData`.
  var usesMockAPI: Bool {
    true
  }
}

// MARK: - Concrete Type

struct AppConfig: AppConfigProtocol {
  var baseUrl: String {
    "https://api.example.com"
  }

  var landingPageBaseUrl: String {
    "https://example.com"
  }
}
