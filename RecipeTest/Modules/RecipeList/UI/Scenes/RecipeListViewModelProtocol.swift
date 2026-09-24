//
//  RecipeListViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// The concrete `RecipeCardViewModel` and `RecipeFacetChipViewModel` are named here rather
/// than their protocols because `SectionState` constrains its value to `Equatable`, which an
/// array of existentials is not. The card and chip *views* still depend on the protocols.
///
/// `viewMode` is read-only with a `select` input rather than a settable property, so the
/// screen keeps the project's callback style and no view needs `@Bindable` over an existential.
@MainActor
protocol RecipeListViewModelProtocol: AnyObject, Observable {
  var title: String { get }
  var searchPlaceholder: String { get }

  var recipes: SectionState<[RecipeCardViewModel]> { get }
  var resultCountText: String? { get }

  var facetChips: [RecipeFacetChipViewModel] { get }
  var showsClearAllChips: Bool { get }

  var emptyTitle: LocalizedStringResource { get }
  var emptyDetail: LocalizedStringResource? { get }
  var showsClearFiltersButton: Bool { get }

  var isLoadingNextPage: Bool { get }
  var nextPageError: String? { get }

  var viewMode: RecipeListViewMode { get }

  func loadFirstPageIfNeeded() async
  func loadFirstPage() async
  func loadNextPageIfNeeded(after cardID: String) async
  func retryNextPage() async
  func remove(facet: RecipeQueryFacet) async
  func clearFacets() async
  func select(viewMode: RecipeListViewMode)
}
