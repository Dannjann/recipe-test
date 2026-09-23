//
//  ThemeFontProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import UIKit

protocol ThemeFontProtocol {
  func primaryBold(ofSize size: CGFloat) -> UIFont
  func primaryRegular(ofSize size: CGFloat) -> UIFont

  func secondaryBold(ofSize size: CGFloat) -> UIFont
  func secondarySemibold(ofSize size: CGFloat) -> UIFont
  func secondaryRegular(ofSize size: CGFloat) -> UIFont
}

// MARK: - Helpers

extension ThemeFontProtocol {
  func customFont(
    _ name: String,
    size: CGFloat
  ) -> UIFont {
    guard
      let font = UIFont(
        name: name,
        size: size
      )
    else {
      preconditionFailure("Could not find font with name: \(name)")
    }

    return font
  }
}
