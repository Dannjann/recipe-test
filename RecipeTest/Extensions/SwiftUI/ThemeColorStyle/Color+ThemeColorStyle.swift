//
//  Color+ThemeColorStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2025 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
  nonisolated enum ThemeColor {
    // Text
    case textPrimary
    case textSecondary
    case textTertiary
    case textDisabled
    case textInverted
    case textWhite
    case textBrandDefault

    // Surfaces
    case surfacesBackground
    case surfacesBackground2
    case surfacesBackground3
    case surfacesFieldsAndTags
    case surfacesDisabled
    case surfacesInverted
    case surfacesBrandDefault
    case surfacesBrandShade1
    case surfacesBrandShade2
    case surfacesBrandShade3

    // Borders
    case bordersDefault
    case bordersDisabled
    case bordersSecondary
    case bordersBrandDefault
    case bordersInverted

    // Icons
    case iconsDefault
    case iconsSecondary
    case iconsTertiary
    case iconsDisabled
    case iconsInverted
    case iconsWhite
    case iconsBrandDefault

    // Complementary
    case complementaryDefault
    case complementaryShade1
    case complementaryShade2
    case complementaryShade3

    // Semantics
    case semanticsSuccessDefault
    case semanticsSuccessShade
    case semanticsInfoDefault
    case semanticsInfoShade
    case semanticsWarningDefault
    case semanticsWarningShade
    case semanticsErrorDefault
    case semanticsErrorShade

    // Accents
    case surfacesAccentPeach
    case surfacesAccentMint
    case surfacesAccentSky
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  static func themeColor(_ colorStyle: ThemeColor) -> Color {
    let theme = ThemeManager.shared.activeTheme.color

    switch colorStyle {
    // Text
    case .textPrimary:
      return theme.textPrimary.color
    case .textSecondary:
      return theme.textSecondary.color
    case .textTertiary:
      return theme.textTertiary.color
    case .textDisabled:
      return theme.textDisabled.color
    case .textInverted:
      return theme.textInverted.color
    case .textWhite:
      return theme.textWhite.color
    case .textBrandDefault:
      return theme.textBrandDefault.color
    // Surfaces
    case .surfacesBackground:
      return theme.surfacesBackground.color
    case .surfacesBackground2:
      return theme.surfacesBackground2.color
    case .surfacesBackground3:
      return theme.surfacesBackground3.color
    case .surfacesFieldsAndTags:
      return theme.surfacesFieldsAndTags.color
    case .surfacesDisabled:
      return theme.surfacesDisabled.color
    case .surfacesInverted:
      return theme.surfacesInverted.color
    case .surfacesBrandDefault:
      return theme.surfacesBrandDefault.color
    case .surfacesBrandShade1:
      return theme.surfacesBrandShade1.color
    case .surfacesBrandShade2:
      return theme.surfacesBrandShade2.color
    case .surfacesBrandShade3:
      return theme.surfacesBrandShade3.color
    // Borders
    case .bordersDefault:
      return theme.bordersDefault.color
    case .bordersDisabled:
      return theme.bordersDisabled.color
    case .bordersSecondary:
      return theme.bordersSecondary.color
    case .bordersBrandDefault:
      return theme.bordersBrandDefault.color
    case .bordersInverted:
      return theme.bordersInverted.color
    // Icons
    case .iconsDefault:
      return theme.iconsDefault.color
    case .iconsSecondary:
      return theme.iconsSecondary.color
    case .iconsTertiary:
      return theme.iconsTertiary.color
    case .iconsDisabled:
      return theme.iconsDisabled.color
    case .iconsInverted:
      return theme.iconsInverted.color
    case .iconsWhite:
      return theme.iconsWhite.color
    case .iconsBrandDefault:
      return theme.iconsBrandDefault.color
    // Complementary
    case .complementaryDefault:
      return theme.complementaryDefault.color
    case .complementaryShade1:
      return theme.complementaryShade1.color
    case .complementaryShade2:
      return theme.complementaryShade2.color
    case .complementaryShade3:
      return theme.complementaryShade3.color
    // Semantics
    case .semanticsSuccessDefault:
      return theme.semanticsSuccessDefault.color
    case .semanticsSuccessShade:
      return theme.semanticsSuccessShade.color
    case .semanticsInfoDefault:
      return theme.semanticsInfoDefault.color
    case .semanticsInfoShade:
      return theme.semanticsInfoShade.color
    case .semanticsWarningDefault:
      return theme.semanticsWarningDefault.color
    case .semanticsWarningShade:
      return theme.semanticsWarningShade.color
    case .semanticsErrorDefault:
      return theme.semanticsErrorDefault.color
    case .semanticsErrorShade:
      return theme.semanticsErrorShade.color
    // Accents
    case .surfacesAccentPeach:
      return theme.surfacesAccentPeach.color
    case .surfacesAccentMint:
      return theme.surfacesAccentMint.color
    case .surfacesAccentSky:
      return theme.surfacesAccentSky.color
    }
  }
}
