//
//  RecipeSearchInputView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSearchInputView: View {
  let viewModel: any RecipeSearchInputViewModelProtocol
  let onBackTap: VoidResult
  let onSelect: SingleResult<RecipeSuggestionRowViewModel>
  let onSubmit: SingleResult<String>

  @State private var text: String
  @FocusState private var isFocused: Bool

  init(
    text: String,
    viewModel: any RecipeSearchInputViewModelProtocol,
    onBackTap: @escaping VoidResult,
    onSelect: @escaping SingleResult<RecipeSuggestionRowViewModel>,
    onSubmit: @escaping SingleResult<String>
  ) {
    _text = State(initialValue: text)
    self.viewModel = viewModel
    self.onBackTap = onBackTap
    self.onSelect = onSelect
    self.onSubmit = onSubmit
  }

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: sectionSpacing
    ) {
      header

      ScrollView(.vertical) {
        VStack(
          alignment: .leading,
          spacing: sectionSpacing
        ) {
          if let queryRow = viewModel.queryRow {
            RecipeSuggestionRow(
              viewModel: queryRow,
              onTap: { onSelect(queryRow) }
            )
          }

          SectionStateView(
            state: viewModel.sections,
            minHeight: sectionMinimumHeight,
            emptyMessage: viewModel.emptyText,
            onRetryTap: { Task { await viewModel.update(text: text) } },
            content: { sections in
              ForEach(sections) { section in
                RecipeSuggestionSection(
                  viewModel: section,
                  onRowTap: onSelect
                )
              }
            }
          )
        }
        .padding(
          .vertical,
          contentInset
        )
      }
      .scrollIndicators(.hidden)
    }
    .background(Color.themeColor(.surfacesBackground))
    .task(id: text) { await viewModel.update(text: text) }
    .onAppear { isFocused = true }
  }
}

// MARK: - Subviews

private extension RecipeSearchInputView {
  var header: some View {
    HStack(spacing: contentSpacing) {
      Button(
        action: onBackTap,
        label: {
          Image(systemName: backSymbolName)
            .foregroundStyle(.themeColor(.iconsDefault))
            .frame(
              width: minimumTargetSize,
              height: minimumTargetSize
            )
            .contentShape(.rect)
        }
      )
      .buttonStyle(.plain)
      .accessibilityIdentifier("recipe-search-input-back-button")
      .accessibilityLabel(Text(.RecipeSearch.recipeSearchInputBackAccessibilityLabel))

      HStack(spacing: contentSpacing) {
        Image(systemName: searchSymbolName)
          .foregroundStyle(.themeColor(.iconsDefault))

        TextField(
          text: $text,
          prompt: Text(.RecipeSearch.recipeSearchFieldPlaceholder),
          label: { Text(.RecipeSearch.recipeSearchFieldPlaceholder) }
        )
        .labelsHidden()
        .themeTextStyle(.bodyRegular)
        .foregroundStyle(.themeColor(.textPrimary))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.search)
        .focused($isFocused)
        .onSubmit { onSubmit(text) }
        .accessibilityIdentifier("recipe-search-input-field")
      }
      .padding(
        .horizontal,
        fieldGutter
      )
      .frame(minHeight: fieldHeight)
      .background(
        Color.themeColor(.surfacesFieldsAndTags),
        in: .capsule
      )
    }
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchInputView {
  var sectionSpacing: CGFloat {
    16
  }

  var contentSpacing: CGFloat {
    10
  }

  var contentInset: CGFloat {
    8
  }

  var horizontalGutter: CGFloat {
    12
  }

  var fieldGutter: CGFloat {
    16
  }

  var fieldHeight: CGFloat {
    48
  }

  var sectionMinimumHeight: CGFloat {
    200
  }

  var minimumTargetSize: CGFloat {
    44
  }

  var backSymbolName: String {
    "chevron.left"
  }

  var searchSymbolName: String {
    "magnifyingglass"
  }
}

#if DEBUG
  #Preview("Idle with recents") {
    RecipeSearchInputView(
      text: "",
      viewModel: MockRecipeSearchInputViewModel.recents(),
      onBackTap: {},
      onSelect: { _ in },
      onSubmit: { _ in }
    )
  }

  #Preview("Idle with nothing") {
    RecipeSearchInputView(
      text: "",
      viewModel: MockRecipeSearchInputViewModel(sections: .empty),
      onBackTap: {},
      onSelect: { _ in },
      onSubmit: { _ in }
    )
  }

  #Preview("Typed with matches") {
    RecipeSearchInputView(
      text: "ado",
      viewModel: MockRecipeSearchInputViewModel.matches(),
      onBackTap: {},
      onSelect: { _ in },
      onSubmit: { _ in }
    )
  }

  #Preview("Loading") {
    RecipeSearchInputView(
      text: "ado",
      viewModel: MockRecipeSearchInputViewModel(
        queryRow: RecipeSuggestionRowViewModel(suggestion: .query("ado")),
        sections: .loading
      ),
      onBackTap: {},
      onSelect: { _ in },
      onSubmit: { _ in }
    )
  }

  #Preview("Failed") {
    RecipeSearchInputView(
      text: "ado",
      viewModel: MockRecipeSearchInputViewModel(
        queryRow: RecipeSuggestionRowViewModel(suggestion: .query("ado")),
        sections: .failed("The request timed out.")
      ),
      onBackTap: {},
      onSelect: { _ in },
      onSubmit: { _ in }
    )
  }
#endif
