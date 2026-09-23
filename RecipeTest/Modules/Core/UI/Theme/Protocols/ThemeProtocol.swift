//
//  ThemeProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import SwiftUI
import UIKit

protocol ThemeProtocol {
  var color: ThemeColorProtocol { get }
  var font: ThemeFontProtocol { get }
  var textStyle: ThemeTextStyleProtocol { get }
}

struct DefaultTheme: ThemeProtocol {
  var color: ThemeColorProtocol = DefaultThemeColor()
  var font: ThemeFontProtocol = DefaultThemeFont()
  var textStyle: ThemeTextStyleProtocol = DefaultThemeTextStyle()
}
