//
//  UTF8ConversionErrorTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

/// `localizedDescription` — not `errorDescription` — is what these assert on. Foundation
/// only routes to `errorDescription` when the type conforms to `LocalizedError`, so
/// reading the property directly would pass with or without the conformance and prove
/// nothing. `debugLogError(_:)` logs `localizedDescription`.
struct UTF8ConversionErrorTests {
  @Test
  func localizedDescription_ofAFailedStringConversion_namesTheEncoding() {
    let sut = UTF8ConversionError.stringConversionFailed(encoding: .isoLatin1)

    #expect(
      sut.localizedDescription
        == String(localized: .Shared.sharedErrorUtf8DataToString(Int(String.Encoding.isoLatin1.rawValue)))
    )
  }

  @Test
  func localizedDescription_ofAFailedUTF8Conversion_isItsOwnText() {
    let sut = UTF8ConversionError.utf8ConversionFailed

    #expect(sut.localizedDescription == String(localized: .Shared.sharedErrorUtf8StringToData))
  }

  /// Guards the actual regression: without the conformance both cases collapse to
  /// Foundation's generic "operation couldn't be completed" text.
  @Test
  func localizedDescription_isNotFoundationsGenericFallback() {
    let sut = UTF8ConversionError.utf8ConversionFailed

    #expect(!sut.localizedDescription.contains("couldn’t be completed"))
    #expect(!sut.localizedDescription.contains("couldn't be completed"))
  }
}
