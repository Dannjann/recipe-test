//
//  DefaultThemeColor.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import UIKit

struct DefaultThemeColor: ThemeColorProtocol {
  // Text
  let textPrimary: ColorResource = .textPrimary
  let textSecondary: ColorResource = .textSecondary
  let textTertiary: ColorResource = .textTertiary
  let textDisabled: ColorResource = .textDisabled
  let textInverted: ColorResource = .textInverted
  let textWhite: ColorResource = .textWhite
  let textBrandDefault: ColorResource = .textBrandDefault

  // Surfaces
  let surfacesBackground: ColorResource = .surfacesBackground
  let surfacesBackground2: ColorResource = .surfacesBackground2
  let surfacesBackground3: ColorResource = .surfacesBackground3
  let surfacesFieldsAndTags: ColorResource = .surfacesFieldsAndTags
  let surfacesDisabled: ColorResource = .surfacesDisabled
  let surfacesInverted: ColorResource = .surfacesInverted
  let surfacesBrandDefault: ColorResource = .surfacesBrandDefault
  let surfacesBrandShade1: ColorResource = .surfacesBrandShade1
  let surfacesBrandShade2: ColorResource = .surfacesBrandShade2
  let surfacesBrandShade3: ColorResource = .surfacesBrandShade3

  // Borders
  let bordersDefault: ColorResource = .bordersDefault
  let bordersDisabled: ColorResource = .bordersDisabled
  let bordersSecondary: ColorResource = .bordersSecondary
  let bordersBrandDefault: ColorResource = .bordersBrandDefault
  let bordersInverted: ColorResource = .bordersInverted

  // Icons
  let iconsDefault: ColorResource = .iconsDefault
  let iconsSecondary: ColorResource = .iconsSecondary
  let iconsTertiary: ColorResource = .iconsTertiary
  let iconsDisabled: ColorResource = .iconsDisabled
  let iconsInverted: ColorResource = .iconsInverted
  let iconsWhite: ColorResource = .iconsWhite
  let iconsBrandDefault: ColorResource = .iconsBrandDefault

  // Complementary
  let complementaryDefault: ColorResource = .complementaryDefault
  let complementaryShade1: ColorResource = .complementaryShade1
  let complementaryShade2: ColorResource = .complementaryShade2
  let complementaryShade3: ColorResource = .complementaryShade3

  // Semantics
  let semanticsSuccessDefault: ColorResource = .semanticsSuccessDefault
  let semanticsSuccessShade: ColorResource = .semanticsSuccessShade
  let semanticsInfoDefault: ColorResource = .semanticsInfoDefault
  let semanticsInfoShade: ColorResource = .semanticsInfoShade
  let semanticsWarningDefault: ColorResource = .semanticsWarningDefault
  let semanticsWarningShade: ColorResource = .semanticsWarningShade
  let semanticsErrorDefault: ColorResource = .semanticsErrorDefault
  let semanticsErrorShade: ColorResource = .semanticsErrorShade
}
