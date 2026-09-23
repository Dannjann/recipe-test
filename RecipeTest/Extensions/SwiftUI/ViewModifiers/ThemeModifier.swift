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
  @ObservedObject var themeManager = ThemeManager.shared

  func body(content: Content) -> some View {
    content.environment(\.theme, themeManager.activeTheme)
  }
}

extension View {
  func themed() -> some View {
    modifier(ThemeModifier())
  }
}
