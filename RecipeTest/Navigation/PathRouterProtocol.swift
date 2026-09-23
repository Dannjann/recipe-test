//
//  PathRouterProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import SwiftUI

/// Every route parameter is generic over `Hashable` rather than taking `AnyHashable`:
/// `navigationDestination(for:)` matches on the *concrete* type of the appended value, and
/// erasing to `AnyHashable` at the call site loses the type the destination is keyed on.
protocol PathRouterProtocol: AnyObject {
  var path: NavigationPath { get set }

  func setRoot(to view: some Hashable)
  func push(_ view: some Hashable)
  func pop()
  func pop(to view: some Hashable)
  func popToRoot()
  func replaceLast(with view: some Hashable)
}
