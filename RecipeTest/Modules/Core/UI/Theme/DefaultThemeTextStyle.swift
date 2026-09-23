//
//  DefaultThemeTextStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import UIKit

/// The concrete font set these text styles are built from.
///
/// Deliberately not `T.font`. `Theme` resolves through `ThemeManager.shared`, and these
/// styles are constructed *during* that manager's own initialisation — `DefaultTheme`
/// composes them — so routing back through `Theme` re-enters a `dispatch_once` that is
/// still in flight and deadlocks on the first read of any token.
private let defaultFont: ThemeFontProtocol = DefaultThemeFont()

struct DefaultThemeTextStyle: ThemeTextStyleProtocol {
  var largeTitle: UIFont = defaultFont.primaryBold(ofSize: 32)
  var title1: UIFont = defaultFont.primaryBold(ofSize: 28)
  var title2: UIFont = defaultFont.primaryBold(ofSize: 24)
  var title3: UIFont = defaultFont.primaryBold(ofSize: 20)
  var title3Regular: UIFont = defaultFont.primaryRegular(ofSize: 20)

  // Non-Headlines
  var bodyBold: UIFont = defaultFont.secondaryBold(ofSize: 16)
  var bodySemibold: UIFont = defaultFont.secondarySemibold(ofSize: 16)
  var bodyRegular: UIFont = defaultFont.secondaryRegular(ofSize: 16)

  var subheadlineSemibold: UIFont = defaultFont.secondarySemibold(ofSize: 14)
  var subheadlineRegular: UIFont = defaultFont.secondaryRegular(ofSize: 14)

  var footnoteBold: UIFont = defaultFont.secondaryBold(ofSize: 12)
  var footnoteRegular: UIFont = defaultFont.secondaryRegular(ofSize: 12)

  var captionBold: UIFont = defaultFont.secondaryBold(ofSize: 11)
  var captionRegular: UIFont = defaultFont.secondaryRegular(ofSize: 11)

  var navigationLabel: UIFont = defaultFont.secondaryRegular(ofSize: 10)
}
