//
//  AppContainer.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
import UIKit

/// Holds the app-wide service instances: config, info, API client, session, network monitor.
///
/// Named for what it is — `App` would collide with SwiftUI's `App` protocol.
///
/// IMPORTANT:
/// - Defer creation of a service instance up to the point where it is first needed.
/// - Services are protocol-typed and injected into coordinators as defaulted initializer
///   parameters, so tests can substitute their own.
@MainActor
final class AppContainer {
  enum Environment: String {
    case staging
    case production
  }

  static let shared = AppContainer()

  /// Set in each target under Build Settings > Other Swift Flags.
  static var environment: Environment {
    #if STAGING
      .staging
    #else
      .production
    #endif
  }

  private(set) lazy var config: any AppConfigProtocol = {
    AppContainer.environment == .production
      ? AppConfig() as any AppConfigProtocol
      : AppConfigStaging()
  }()

  private(set) lazy var monitoring: MonitoringServiceProtocol = DebugLogMonitoringService()

  private(set) lazy var api: APIClient = {
    // Resolved here, on the main actor, so the closure below captures it directly.
    // Capturing `self` would reach back into main-actor state from the networking
    // layer, which runs nonisolated.
    let monitoring = monitoring

    // The first thing a generated project changes is `AppConfig.baseUrl`. A typo there
    // would otherwise surface as a bare `Fatal error: Unexpectedly found nil` with no clue
    // which value was wrong.
    guard let baseURL = URL(string: config.apiUrl) else {
      preconditionFailure("AppConfig.apiUrl is not a valid URL: \(config.apiUrl)")
    }

    return APIClient(
      sessionManager: config.usesMockAPI ? .mocked() : .default,
      baseURL: baseURL,
      version: config.apiVersion,
      onError: { error in
        monitoring.logError(error)
      }
    )
  }()

  // MARK: Feature services

  private(set) lazy var recipeService: RecipeServiceProtocol = {
    // Resolved here for the same reason `api` does it: the closure is `@Sendable` and
    // the service is nonisolated, so capturing `self` would reach main-actor state from
    // off the main actor.
    let monitoring = monitoring

    return RecipeService(
      api: api,
      onError: { error in
        monitoring.logError(error)
      }
    )
  }()

  private(set) lazy var recentSearchStore: RecentSearchStoreProtocol =
    RecentSearchStore(store: UserDefaultsClient())

  private init() {
    debugLog("env: \(AppContainer.environment.rawValue)")
  }
}

// MARK: - Bootstrap

extension AppContainer {
  /// Called once from the app delegate. Everything it touches is lazy, so this is where
  /// you decide what is eagerly constructed at launch.
  func bootstrap() {
    UINavigationBar.applyThemeAppearance()

    // Debug builds only. A release build leaves every context disabled, so nothing a
    // developer logs while working can follow the app into the App Store — see the
    // matching privacy marker in `DebugLogger.log`.
    #if DEBUG
      let debugLogger = DebugLogger.shared
      debugLogger.enable(.networking)
      debugLogger.enable(.appError)
      debugLogger.enable(.debugging)
    #endif

    // Demo builds answer every *data* request from `Resources/MockData` instead of the
    // network. Photographs are deliberately left alone: the fixture points at real hosts,
    // and Kingfisher keeps its own URLSession, so they load for real.
    // Switch `failureMode` to `.serverError` or `.empty` to demonstrate the error and
    // empty states without touching any feature code.
    if config.usesMockAPI {
      MockURLProtocol.router = MockAPIRouter(
        configuration: .init(
          latency: .milliseconds(400),
          failureMode: .none
        )
      )
    }

    _ = api
  }
}
