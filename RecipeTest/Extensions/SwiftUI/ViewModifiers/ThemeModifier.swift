//
//  ThemeModifier.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

struct ThemeModifier: ViewModifier {
  /// A plain `let`, not `@State`: the modifier does not own the manager, and `@Observable`
  /// tracks the read of `activeTheme` below on its own.
  private let themeManager = ThemeManager.shared

  func body(content: Content) -> some View {
    content.environment(\.theme, themeManager.activeTheme)
  }
}

extension View {
  func themed() -> some View {
    modifier(ThemeModifier())
  }
}
