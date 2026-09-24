//
//  View+FieldCapsule.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

extension View {
  /// Fill and edge for the capsule-shaped search fields. The fill is white on a cream ground,
  /// so without the border the control reads as a gap in the page rather than something to tap.
  func fieldCapsule() -> some View {
    background(
      Color.themeColor(.surfacesFieldsAndTags),
      in: .capsule
    )
    .overlay(
      Capsule()
        .strokeBorder(
          Color.themeColor(.bordersDefault),
          lineWidth: 1
        )
    )
  }
}
