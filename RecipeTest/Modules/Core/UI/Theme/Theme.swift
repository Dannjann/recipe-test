//
//  Theme.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2021 Danjan. All rights reserved.
//
// swiftlint: disable type_name

import UIKit

typealias T = Theme

/// The token vocabulary, as the UIKit lane reads it.
///
/// These are computed, not stored: they resolve through `ThemeManager.shared.activeTheme`,
/// the same source the SwiftUI extensions read. They used to be `static let`s holding their
/// own `Default*` instances, so swapping `activeTheme` restyled SwiftUI while every `T.*`
/// call site kept serving the old values.
enum Theme {
  static var color: ThemeColorProtocol {
    ThemeManager.shared.activeTheme.color
  }

  static var font: ThemeFontProtocol {
    ThemeManager.shared.activeTheme.font
  }

  static var textStyle: ThemeTextStyleProtocol {
    ThemeManager.shared.activeTheme.textStyle
  }
}

// swiftlint: enable type_name
