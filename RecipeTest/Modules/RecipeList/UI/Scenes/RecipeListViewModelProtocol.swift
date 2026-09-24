//
//  RecipeListViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Concrete row view models rather than their protocols: `SectionState` needs `Equatable` and
/// `ForEach` needs `Identifiable`, neither of which an array of existentials satisfies.
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
  var nextPageErrorText: String? { get }

  var viewMode: RecipeListViewMode { get }
  var viewModeSegments: [RecipeListViewModeSegmentViewModel] { get }

  func loadFirstPageIfNeeded() async
  func loadFirstPage() async
  func loadNextPageIfNeeded(after cardID: String) async
  func retryNextPage() async
  func remove(facet: RecipeQueryFacet) async
  func clearFacets() async
  func select(viewMode: RecipeListViewMode)
}
