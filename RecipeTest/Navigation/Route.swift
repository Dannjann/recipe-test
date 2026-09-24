//
//  Route.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Destinations pushed onto a `PathRouter`'s `NavigationPath`.
///
/// One nested `Hashable` enum per module keeps route names from colliding as the app
/// grows: `Route.Settings.profile`, `Route.Catalog.detail(item)`, and so on.
///
/// Empty until the first module lands. Add its routes as a nested enum:
///
///     enum Route {
///       enum Catalog: Hashable {
///         case detail(Item)
///       }
///     }
///
/// then handle them with `navigationDestination(for: Route.Catalog.self)` in that
/// module's coordinator. `PathRouter` is generic over `Hashable`, so nothing here has to
/// change for a new module to start routing.
enum Route {
  enum Recipe: Hashable {
    case detail(RecipeSummary)
    case list(RecipeListRequest)
  }
}
