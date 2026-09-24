//
//  RecipeSearchView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSearchView: View {
  let viewModel: any RecipeSearchViewModelProtocol
  let onCloseTap: VoidResult
  let onFieldTap: VoidResult
  let onSubmitTap: VoidResult

  var body: some View {
    VStack(spacing: 0) {
      header

      ScrollView(.vertical) {
        VStack(spacing: sectionSpacing) {
          whatSection
          vegetarianSection
          servingsSection
          includeSection
          excludeSection
          stepsSection
        }
        .padding(
          .vertical,
          contentInset
        )
      }
      .scrollIndicators(.hidden)

      RecipeSearchFooter(
        showsClearAll: viewModel.showsClearAll,
        onClearAllTap: { viewModel.clearAll() },
        onSubmitTap: onSubmitTap
      )
    }
    .background(Color.themeColor(.surfacesBackground))
  }
}

// MARK: - Subviews

private extension RecipeSearchView {
  var header: some View {
    HStack {
      Spacer(minLength: 0)

      Button(
        action: onCloseTap,
        label: {
          Image(systemName: closeSymbolName)
            .foregroundStyle(.themeColor(.iconsDefault))
            .frame(
              width: minimumTargetSize,
              height: minimumTargetSize
            )
            .contentShape(.rect)
        }
      )
      .buttonStyle(.plain)
      .accessibilityIdentifier("recipe-search-close-button")
      .accessibilityLabel(Text(.RecipeSearch.recipeSearchCloseAccessibilityLabel))
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
  }

  var whatSection: some View {
    RecipeSearchSection(title: .RecipeSearch.recipeSearchSectionWhatTitle) {
      RecipeSearchFieldButton(
        text: viewModel.fieldText,
        isPlaceholder: !viewModel.hasFieldText,
        showsClear: viewModel.hasFieldText,
        onTap: onFieldTap,
        onClearTap: { viewModel.set(searchText: "") }
      )
    }
  }

  var vegetarianSection: some View {
    RecipeSearchSection(title: nil) {
      RecipeSearchToggleRow(
        title: .RecipeSearch.recipeSearchSectionVegetarianTitle,
        detail: .RecipeSearch.recipeSearchSectionVegetarianDetail,
        isOn: viewModel.isVegetarian,
        accessibilityIdentifier: "recipe-search-vegetarian-toggle",
        onToggle: { viewModel.toggleVegetarian() }
      )
    }
  }

  var servingsSection: some View {
    RecipeSearchSection(title: .RecipeSearch.recipeSearchSectionServingsTitle) {
      RecipeServingsPicker(
        options: viewModel.servingsOptions,
        onSelect: { viewModel.select(servings: $0) }
      )
    }
  }

  var includeSection: some View {
    RecipeSearchSection(title: .RecipeSearch.recipeSearchSectionIncludeTitle) {
      RecipeIngredientEntry(
        placeholder: .RecipeSearch.recipeSearchSectionIncludePlaceholder,
        fieldAccessibilityIdentifier: "recipe-search-include-field",
        addAccessibilityIdentifier: "recipe-search-include-add-button",
        onAdd: { viewModel.addInclude($0) }
      )

      RecipeIngredientChipRow(
        chips: viewModel.includeChips,
        onRemoveTap: { viewModel.remove(chip: $0) }
      )
    }
  }

  var excludeSection: some View {
    RecipeSearchSection(title: .RecipeSearch.recipeSearchSectionExcludeTitle) {
      RecipeIngredientEntry(
        placeholder: .RecipeSearch.recipeSearchSectionExcludePlaceholder,
        fieldAccessibilityIdentifier: "recipe-search-exclude-field",
        addAccessibilityIdentifier: "recipe-search-exclude-add-button",
        onAdd: { viewModel.addExclude($0) }
      )

      RecipeIngredientChipRow(
        chips: viewModel.excludeChips,
        onRemoveTap: { viewModel.remove(chip: $0) }
      )
    }
  }

  var stepsSection: some View {
    RecipeSearchSection(title: nil) {
      RecipeSearchToggleRow(
        title: .RecipeSearch.recipeSearchSectionStepsTitle,
        detail: .RecipeSearch.recipeSearchSectionStepsDetail,
        isOn: viewModel.searchesSteps,
        accessibilityIdentifier: "recipe-search-steps-toggle",
        onToggle: { viewModel.toggleSearchesSteps() }
      )
    }
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchView {
  var sectionSpacing: CGFloat {
    16
  }

  var contentInset: CGFloat {
    12
  }

  var horizontalGutter: CGFloat {
    12
  }

  var closeSymbolName: String {
    "xmark"
  }

  var minimumTargetSize: CGFloat {
    44
  }
}

#if DEBUG
  #Preview("Empty draft") {
    RecipeSearchView(
      viewModel: MockRecipeSearchViewModel.empty(),
      onCloseTap: {},
      onFieldTap: {},
      onSubmitTap: {}
    )
  }

  #Preview("Everything set") {
    RecipeSearchView(
      viewModel: MockRecipeSearchViewModel.filled(),
      onCloseTap: {},
      onFieldTap: {},
      onSubmitTap: {}
    )
  }

  #Preview("Text only") {
    RecipeSearchView(
      viewModel: MockRecipeSearchViewModel(
        fieldText: "adobo",
        hasFieldText: true
      ),
      onCloseTap: {},
      onFieldTap: {},
      onSubmitTap: {}
    )
  }

  #Preview("Filters only") {
    RecipeSearchView(
      viewModel: MockRecipeSearchViewModel(
        isVegetarian: true,
        servings: .sixOrMore,
        excludeIngredients: ["pork"]
      ),
      onCloseTap: {},
      onFieldTap: {},
      onSubmitTap: {}
    )
  }
#endif
