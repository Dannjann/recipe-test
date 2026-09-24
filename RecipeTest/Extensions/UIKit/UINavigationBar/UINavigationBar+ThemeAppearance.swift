//
//  UINavigationBar+ThemeAppearance.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import UIKit

extension UINavigationBar {
  func applyThemeAppearance() {
    standardAppearance = .themedStandard
    compactAppearance = .themedStandard
    scrollEdgeAppearance = .themedScrollEdge
    compactScrollEdgeAppearance = .themedScrollEdge
  }

  static func applyThemeAppearance() {
    UINavigationBar.appearance().applyThemeAppearance()
  }
}

// MARK: - Appearances

extension UINavigationBarAppearance {
  static var themedStandard: UINavigationBarAppearance {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithDefaultBackground()
    appearance.applyThemeTitleAttributes()

    return appearance
  }

  static var themedScrollEdge: UINavigationBarAppearance {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()
    appearance.applyThemeTitleAttributes()

    return appearance
  }
}

// MARK: - Title attributes

private extension UINavigationBarAppearance {
  func applyThemeTitleAttributes() {
    largeTitleTextAttributes = Self.largeTitleThemeAttributes
    titleTextAttributes = Self.titleThemeAttributes
  }
}

// MARK: - Getters

private extension UINavigationBarAppearance {
  static var largeTitleThemeAttributes: [NSAttributedString.Key: Any] {
    [
      .font: T.textStyle.largeTitle,
      .foregroundColor: T.color.textPrimary.uiColor
    ]
  }

  static var titleThemeAttributes: [NSAttributedString.Key: Any] {
    [
      .font: T.textStyle.title2,
      .foregroundColor: T.color.textPrimary.uiColor
    ]
  }
}
