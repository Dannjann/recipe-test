//
//  Font+ThemeTextStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

extension Font {
  /// replicate `UIFont.TextStyle`
  enum ThemeTextStyle: CaseIterable {
    case largeTitle
    case title1
    case title2
    case title3
    case title3Regular

    case bodyBold
    case bodySemibold
    case bodyRegular

    case subheadlineSemibold
    case subheadlineRegular

    case footnoteBold
    case footnoteRegular

    case captionBold
    case captionRegular

    case navigationLabel
  }

  // swiftlint:disable:next cyclomatic_complexity
  static func themeTextStyle(_ textStyle: ThemeTextStyle) -> Font {
    let theme = ThemeManager.shared.activeTheme.textStyle

    switch textStyle {
    case .largeTitle:
      return theme.largeTitle.font
    case .title1:
      return theme.title1.font
    case .title2:
      return theme.title2.font
    case .title3:
      return theme.title3.font
    case .title3Regular:
      return theme.title3Regular.font
    case .bodyBold:
      return theme.bodyBold.font
    case .bodySemibold:
      return theme.bodySemibold.font
    case .bodyRegular:
      return theme.bodyRegular.font
    case .subheadlineSemibold:
      return theme.subheadlineSemibold.font
    case .subheadlineRegular:
      return theme.subheadlineRegular.font
    case .footnoteBold:
      return theme.footnoteBold.font
    case .footnoteRegular:
      return theme.footnoteRegular.font
    case .captionBold:
      return theme.captionBold.font
    case .captionRegular:
      return theme.captionRegular.font
    case .navigationLabel:
      return theme.navigationLabel.font
    }
  }
}
