//
//  ThemeColorProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import SwiftUI
import UIKit

protocol ThemeColorProtocol {
  // Text
  var textPrimary: ColorResource { get }
  var textSecondary: ColorResource { get }
  var textTertiary: ColorResource { get }
  var textDisabled: ColorResource { get }
  var textInverted: ColorResource { get }
  var textWhite: ColorResource { get }
  var textBrandDefault: ColorResource { get }

  // Surfaces
  var surfacesBackground: ColorResource { get }
  var surfacesBackground2: ColorResource { get }
  var surfacesBackground3: ColorResource { get }
  var surfacesFieldsAndTags: ColorResource { get }
  var surfacesDisabled: ColorResource { get }
  var surfacesInverted: ColorResource { get }
  var surfacesBrandDefault: ColorResource { get }
  var surfacesBrandShade1: ColorResource { get }
  var surfacesBrandShade2: ColorResource { get }
  var surfacesBrandShade3: ColorResource { get }

  // Borders
  var bordersDefault: ColorResource { get }
  var bordersDisabled: ColorResource { get }
  var bordersSecondary: ColorResource { get }
  var bordersBrandDefault: ColorResource { get }
  var bordersInverted: ColorResource { get }

  // Icons
  var iconsDefault: ColorResource { get }
  var iconsSecondary: ColorResource { get }
  var iconsTertiary: ColorResource { get }
  var iconsDisabled: ColorResource { get }
  var iconsInverted: ColorResource { get }
  var iconsWhite: ColorResource { get }
  var iconsBrandDefault: ColorResource { get }

  // Complementary
  var complementaryDefault: ColorResource { get }
  var complementaryShade1: ColorResource { get }
  var complementaryShade2: ColorResource { get }
  var complementaryShade3: ColorResource { get }

  // Semantics
  var semanticsSuccessDefault: ColorResource { get }
  var semanticsSuccessShade: ColorResource { get }
  var semanticsInfoDefault: ColorResource { get }
  var semanticsInfoShade: ColorResource { get }
  var semanticsWarningDefault: ColorResource { get }
  var semanticsWarningShade: ColorResource { get }
  var semanticsErrorDefault: ColorResource { get }
  var semanticsErrorShade: ColorResource { get }
}
