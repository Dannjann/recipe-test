//
//  View+CardShadow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

extension View {
  /// Two layers, brand brown rather than black: a neutral shadow on a cream ground reads grey.
  func cardShadow() -> some View {
    shadow(
      color: .themeColor(.textPrimary).opacity(0.08),
      radius: 1.5,
      y: 1
    )
    .shadow(
      color: .themeColor(.textPrimary).opacity(0.12),
      radius: 14,
      y: 10
    )
  }
}
