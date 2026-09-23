//
//  EnvironmentValues+ThemeKey.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

extension EnvironmentValues {
  var theme: any ThemeProtocol {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }

  struct ThemeKey: EnvironmentKey {
    /// Computed, not stored: a stored `static var` is initialised once on first access and
    /// would pin the default to whichever theme happened to be active at that moment.
    static var defaultValue: any ThemeProtocol {
      ThemeManager.shared.activeTheme
    }
  }
}
