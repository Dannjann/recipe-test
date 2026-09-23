//
//  RecipeTestApp.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI
import UIKit

@main
struct RecipeTestApp: App {
  init() {
    guard !UIApplication.isRunningTests else { return }

    AppContainer.shared.bootstrap()
  }

  var body: some Scene {
    WindowGroup {
      // Under `xcodebuild test` the app still has to present a scene — but building
      // `AppCoordinator` here would resolve the container's services and let the root
      // screen's `.task` fire a request before the first test runs.
      if UIApplication.isRunningTests {
        Color.clear
      } else {
        AppCoordinator()
          .themed()
      }
    }
  }
}
