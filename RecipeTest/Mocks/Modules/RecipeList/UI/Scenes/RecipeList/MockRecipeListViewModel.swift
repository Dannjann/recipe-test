//
//  MockRecipeListViewModel.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

#if DEBUG
  @Observable
  final class MockRecipeListViewModel: RecipeListViewModelProtocol {
    var title: String
    var searchPlaceholder: String
    var recipes: SectionState<[RecipeCardViewModel]>
    var resultCountText: String?
    var facetChips: [RecipeFacetChipViewModel]
    var emptyTitle: LocalizedStringResource
    var emptyDetail: LocalizedStringResource?
    var showsClearFiltersButton: Bool
    var isLoadingNextPage: Bool
    var nextPageErrorText: String?
    var viewMode: RecipeListViewMode

    init(
      title: String = "Desserts",
      searchPlaceholder: String = "Search Desserts",
      recipes: SectionState<[RecipeCardViewModel]> = .loading,
      resultCountText: String? = nil,
      facetChips: [RecipeFacetChipViewModel] = [],
      emptyTitle: LocalizedStringResource = .RecipeList.recipeListEmptyNoResultsTitle,
      emptyDetail: LocalizedStringResource? = nil,
      showsClearFiltersButton: Bool = false,
      isLoadingNextPage: Bool = false,
      nextPageErrorText: String? = nil,
      viewMode: RecipeListViewMode = .grid
    ) {
      self.title = title
      self.searchPlaceholder = searchPlaceholder
      self.recipes = recipes
      self.resultCountText = resultCountText
      self.facetChips = facetChips
      self.emptyTitle = emptyTitle
      self.emptyDetail = emptyDetail
      self.showsClearFiltersButton = showsClearFiltersButton
      self.isLoadingNextPage = isLoadingNextPage
      self.nextPageErrorText = nextPageErrorText
      self.viewMode = viewMode
    }
  }

  // MARK: - Getters

  extension MockRecipeListViewModel {
    var showsClearAllChips: Bool {
      facetChips.count > 1
    }

    var viewModeSegments: [RecipeListViewModeSegmentViewModel] {
      RecipeListViewMode.allCases.map {
        RecipeListViewModeSegmentViewModel(
          mode: $0,
          isSelected: $0 == viewMode
        )
      }
    }
  }

  // MARK: - Inputs

  extension MockRecipeListViewModel {
    func loadFirstPageIfNeeded() async {}

    func loadFirstPage() async {}

    func loadNextPageIfNeeded(after cardID: String) async {}

    func retryNextPage() async {}

    func remove(facet: RecipeQueryFacet) async {}

    func clearFacets() async {}

    func apply(query: RecipeQuery) async {}

    func select(viewMode: RecipeListViewMode) {
      self.viewMode = viewMode
    }
  }

  // MARK: - Scenarios

  extension MockRecipeListViewModel {
    static func loaded(viewMode: RecipeListViewMode = .grid) -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "6 recipes",
        viewMode: viewMode
      )
    }

    static func loading() -> MockRecipeListViewModel {
      MockRecipeListViewModel(recipes: .loading)
    }

    static func filtered() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "2 recipes",
        facetChips: [
          RecipeFacetChipViewModel(facet: .vegetarian(true)),
          RecipeFacetChipViewModel(facet: .servings(.four)),
          RecipeFacetChipViewModel(facet: .exclude("peanuts")),
        ]
      )
    }

    static func emptyCategory() -> MockRecipeListViewModel {
      MockRecipeListViewModel(recipes: .empty)
    }

    static func emptyFiltered() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .empty,
        facetChips: [RecipeFacetChipViewModel(facet: .vegetarian(true))],
        emptyTitle: .RecipeList.recipeListEmptyTitle,
        emptyDetail: .RecipeList.recipeListEmptyDetail,
        showsClearFiltersButton: true
      )
    }

    static func failed() -> MockRecipeListViewModel {
      MockRecipeListViewModel(recipes: .failed("The Internet connection appears to be offline."))
    }

    static func paging() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "36 recipes",
        isLoadingNextPage: true
      )
    }

    static func pagingFailed() -> MockRecipeListViewModel {
      MockRecipeListViewModel(
        recipes: .loaded(sampleCards),
        resultCountText: "36 recipes",
        nextPageErrorText: "The Internet connection appears to be offline."
      )
    }
  }

  // MARK: - Getters > Samples

  extension MockRecipeListViewModel {
    static var sampleCards: [RecipeCardViewModel] {
      [
        sampleCard(
          id: "rcp-001",
          title: "Chicken Adobo",
          cuisine: "filipino",
          category: "Meal"
        ),
        sampleCard(
          id: "rcp-002",
          title: "Pavlova",
          cuisine: "australian",
          category: "Desserts"
        ),
        sampleCard(
          id: "rcp-003",
          title: "Gỏi Cuốn",
          cuisine: "vietnamese",
          category: "Snacks"
        ),
        sampleCard(
          id: "rcp-004",
          title: "Pão de Queijo",
          cuisine: "brazilian",
          category: "Snacks"
        ),
      ]
    }

    static var bareCard: RecipeCardViewModel {
      RecipeCardViewModel(summary: .dummy(
        id: "rcp-099",
        title: "Sinangag",
        heroImageURL: nil,
        category: nil,
        cuisine: nil,
        totalTimeMinutes: nil,
        servings: nil
      ))
    }

    private static func sampleCard(
      id: String,
      title: String,
      cuisine: String,
      category: String
    ) -> RecipeCardViewModel {
      RecipeCardViewModel(summary: .dummy(
        id: id,
        title: title,
        heroImageURL: nil,
        category: category,
        cuisine: cuisine
      ))
    }
  }
#endif
