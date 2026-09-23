//
//  MonitoringServiceProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// A seam, not a feature.
///
/// `APIClient` reports errors here instead of naming a crash reporter. Add Sentry,
/// Crashlytics, or anything else by conforming a client to this protocol and injecting
/// it — no edit to `APIClient` required.
nonisolated protocol MonitoringServiceProtocol: Sendable {
  func logError(_ error: Error)
}

// MARK: - Default implementation

/// Writes to `DebugLogger`. Replace by injecting your own conformer.
nonisolated struct DebugLogMonitoringService: MonitoringServiceProtocol {
  func logError(_ error: Error) {
    debugLogError(error)
  }
}
