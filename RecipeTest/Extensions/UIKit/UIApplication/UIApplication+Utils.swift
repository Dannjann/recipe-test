//
//  UIApplication+Utils.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2018 Danjan. All rights reserved.
//

import UIKit

extension UIApplication {
  /// Lets the app entry point skip building the container and the root screen under
  /// `xcodebuild test`, so a unit-test run never fires a request.
  static var isRunningTests: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  }
}
