//
//  View+ThemeTextStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

/// replicate SwiftUI `font(_ font: Font?) -> some View`
extension View {
  func themeTextStyle(_ textStyle: Font.ThemeTextStyle) -> some View {
    font(.themeTextStyle(textStyle))
  }
}
