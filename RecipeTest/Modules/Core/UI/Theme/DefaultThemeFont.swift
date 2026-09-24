//
//  DefaultThemeFont.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import UIKit

// MARK: - Primary

// Primary fonts are fonts that are most used by the app.
// Usually applied to headlines.

struct DefaultThemeFont: ThemeFontProtocol {
  func primaryBold(ofSize size: CGFloat) -> UIFont {
    customFont("Unna-Bold", size: size)
  }

  func primaryRegular(ofSize size: CGFloat) -> UIFont {
    customFont("Unna-Regular", size: size)
  }
}

// MARK: - Secondary

// Secondary fonts are fonts that have a different typeface from your primary.
// Usually applied to non-headlines (body/sub-headlines/footnote/captions).

extension DefaultThemeFont {
  func secondaryBold(ofSize size: CGFloat) -> UIFont {
    customFont("AtkinsonHyperlegible-Bold", size: size)
  }

  /// Atkinson Hyperlegible ships no semibold weight, so this resolves to bold.
  func secondarySemibold(ofSize size: CGFloat) -> UIFont {
    customFont("AtkinsonHyperlegible-Bold", size: size)
  }

  func secondaryRegular(ofSize size: CGFloat) -> UIFont {
    customFont("AtkinsonHyperlegible-Regular", size: size)
  }
}
