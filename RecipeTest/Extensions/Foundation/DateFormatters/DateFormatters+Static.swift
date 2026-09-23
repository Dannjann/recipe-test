//
//  DateFormatters+Static.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2020 Danjan. All rights reserved.
//

import Foundation

nonisolated extension DateFormatter {
  /// Both formatters below pin `locale` to `en_US_POSIX`.
  ///
  /// A `dateFormat` is only fixed if the locale is too. Left on the device locale, a
  /// user with 12-hour time set can fail to parse `HH`, and some regions substitute
  /// their own digits — so the same API string parses on one device and returns `nil`
  /// on another. Apple's QA1480 covers this.
  static let iso8601: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    return formatter
  }()

  static let birthdateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()
}
