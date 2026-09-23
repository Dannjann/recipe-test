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
//
// The base ships no bundled typeface — these resolve to the system font so a fresh
// project runs unbranded. To brand an app, drop the font files into Resources/Fonts,
// list them under UIAppFonts in Info.plist, and swap these bodies for `customFont(_:size:)`.

struct DefaultThemeFont: ThemeFontProtocol {
  func primaryBold(ofSize size: CGFloat) -> UIFont {
    .systemFont(ofSize: size, weight: .bold)
  }

  func primaryRegular(ofSize size: CGFloat) -> UIFont {
    .systemFont(ofSize: size, weight: .regular)
  }
}

// MARK: - Secondary

// Secondary fonts are fonts that have a different typeface from your primary.
// Usually applied to non-headlines (body/sub-headlines/footnote/captions).

extension DefaultThemeFont {
  func secondaryBold(ofSize size: CGFloat) -> UIFont {
    .systemFont(ofSize: size, weight: .bold)
  }

  func secondarySemibold(ofSize size: CGFloat) -> UIFont {
    .systemFont(ofSize: size, weight: .semibold)
  }

  func secondaryRegular(ofSize size: CGFloat) -> UIFont {
    .systemFont(ofSize: size, weight: .regular)
  }
}
