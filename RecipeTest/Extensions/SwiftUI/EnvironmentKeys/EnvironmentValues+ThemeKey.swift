//
//  EnvironmentValues+ThemeKey.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

/// Stored once rather than written inline as the `@Entry` default. An inline `DefaultTheme()`
/// is rebuilt on every fallback read, and SwiftUI cannot see two of them as the same value —
/// any unrelated environment write would then look like a theme change to every view that
/// falls back to it.
private let defaultTheme: any ThemeProtocol = DefaultTheme()

extension EnvironmentValues {
  /// The fallback is the default theme, not whichever theme happens to be active: the
  /// active one arrives through `.themed()`, which is applied at the root and observes
  /// `ThemeManager` so a swap actually redraws.
  @Entry var theme: any ThemeProtocol = defaultTheme
}
