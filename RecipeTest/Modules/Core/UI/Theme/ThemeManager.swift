//
//  ThemeManager.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation

/// The single source of the active theme, for both lanes: SwiftUI observes it through
/// `ThemeModifier`, and `Theme` (`T.*`) reads it for UIKit.
@Observable
final class ThemeManager {
  var activeTheme: any ThemeProtocol = DefaultTheme()

  static let shared = ThemeManager()
  private init() {}
}
