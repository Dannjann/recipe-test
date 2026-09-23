//
//  ThemeTextStyleProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import UIKit

protocol ThemeTextStyleProtocol {
  var largeTitle: UIFont { get }
  var title1: UIFont { get }
  var title2: UIFont { get }
  var title3: UIFont { get }
  var title3Regular: UIFont { get }

  var bodyBold: UIFont { get }
  var bodySemibold: UIFont { get }
  var bodyRegular: UIFont { get }

  var subheadlineSemibold: UIFont { get }
  var subheadlineRegular: UIFont { get }

  var footnoteBold: UIFont { get }
  var footnoteRegular: UIFont { get }

  var captionBold: UIFont { get }
  var captionRegular: UIFont { get }

  var navigationLabel: UIFont { get }
}
