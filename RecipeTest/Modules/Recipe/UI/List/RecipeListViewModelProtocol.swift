//
//  RecipeListViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What `RecipeListView` depends on, so the screen can be previewed and tested against a
/// double instead of a service.
///
/// Inherits `Observable` so a conformer that forgot the `@Observable` macro fails to
/// compile rather than silently never updating the view.
///
/// Held by the view as `any RecipeListViewModelProtocol`. Reading through the existential
/// tracks correctly — the protocol witness dispatches to the macro-generated accessor,
/// which registers with the current observation context exactly as a concrete call would.
/// What does *not* work is `@Bindable` on an existential; `Observable` has no
/// self-conformance, so `$viewModel.layout` will not compile. That costs nothing here
/// because inputs are methods and outputs are read-only, per the team's MVVM standard —
/// which is why `select(layout:)` exists instead of a settable `layout`.
@MainActor
protocol RecipeListViewModelProtocol: Observable, AnyObject {
  // MARK: Outputs

  var recipes: [RecipeSummary] { get }
  var layout: RecipeListLayout { get }
  var loadState: RecipeListLoadState { get }
  /// A page beyond the first is in flight. Drives the footer, never the screen.
  var isLoadingNextPage: Bool { get }
  /// A page beyond the first failed. Drives the footer's retry, never the screen.
  var nextPageError: String? { get }
  var hasLoadedAllData: Bool { get }

  // MARK: Inputs

  func loadFirstPage() async
  func refresh() async
  func loadNextPage() async
  func select(layout: RecipeListLayout)
}
