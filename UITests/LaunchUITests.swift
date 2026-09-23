//
//  LaunchUITests.swift
//  UITests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import XCTest

/// XCTest rather than Swift Testing — XCUITest still requires it.
final class LaunchUITests: XCTestCase {
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func test_app_launches() {
    let app = XCUIApplication()
    app.launch()

    XCTAssertEqual(app.state, .runningForeground)
  }
}
