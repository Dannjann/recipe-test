//
//  View+CardShadow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

extension View {
  /// The prototype's one elevation, used by every raised surface on Home — the search
  /// pill, the carousel cards and the category tiles.
  ///
  /// Two layers, because the CSS it comes from has two:
  /// `0 1px 3px rgba(74,43,30,.08), 0 10px 28px rgba(74,43,30,.12)`. A CSS blur radius is
  /// roughly twice SwiftUI's, which is where 3 -> 1.5 and 28 -> 14 come from. The colour
  /// is the brand brown rather than black: a neutral shadow on a cream ground reads grey.
  func cardShadow() -> some View {
    shadow(color: .themeColor(.textPrimary).opacity(0.08), radius: 1.5, y: 1)
      .shadow(color: .themeColor(.textPrimary).opacity(0.12), radius: 14, y: 10)
  }
}
