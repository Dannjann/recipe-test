//
//  ColorResource+helper.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2025 Danjan. All rights reserved.
//

import SwiftUI
import UIKit

nonisolated extension ColorResource {
  var uiColor: UIColor {
    UIColor(resource: self)
  }

  var color: Color {
    Color(uiColor: uiColor)
  }
}
