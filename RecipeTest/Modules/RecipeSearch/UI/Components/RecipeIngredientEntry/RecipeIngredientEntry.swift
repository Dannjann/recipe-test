//
//  RecipeIngredientEntry.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Owns its text: what is half-typed here is local input on its way to the view model, not a
/// value the view model renders, and keeping it out avoids a `@Bindable` over an existential.
struct RecipeIngredientEntry: View {
  let placeholder: LocalizedStringResource
  let fieldAccessibilityIdentifier: String
  let addAccessibilityIdentifier: String
  let onAdd: SingleResult<String>

  @State private var text = ""

  var body: some View {
    HStack(spacing: contentSpacing) {
      TextField(
        text: $text,
        prompt: Text(placeholder),
        label: { Text(placeholder) }
      )
      .labelsHidden()
      .themeTextStyle(.bodyRegular)
      .foregroundStyle(.themeColor(.textPrimary))
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .submitLabel(.done)
      .onSubmit(add)
      .padding(
        .horizontal,
        fieldGutter
      )
      .frame(minHeight: fieldHeight)
      .background(
        Color.themeColor(.surfacesFieldsAndTags),
        in: .capsule
      )
      .accessibilityIdentifier(fieldAccessibilityIdentifier)

      Button(
        action: add,
        label: {
          HStack(spacing: labelSpacing) {
            Image(systemName: addSymbolName)

            Text(.RecipeSearch.recipeSearchAddTitle)
          }
          .themeTextStyle(.bodyBold)
          .foregroundStyle(.themeColor(.textInverted))
          .padding(
            .horizontal,
            buttonGutter
          )
          .frame(minHeight: fieldHeight)
          .background(
            Color.themeColor(.surfacesBrandDefault),
            in: .capsule
          )
          .contentShape(.capsule)
        }
      )
      .buttonStyle(.plain)
      .accessibilityIdentifier(addAccessibilityIdentifier)
    }
  }
}

// MARK: - Handlers

private extension RecipeIngredientEntry {
  /// Cleared unconditionally: the view model ignores a blank add, and leaving the word behind
  /// after a successful one invites adding it twice.
  func add() {
    onAdd(text)
    text = ""
  }
}

// MARK: - Getters > Constants

private extension RecipeIngredientEntry {
  var contentSpacing: CGFloat {
    8
  }

  var labelSpacing: CGFloat {
    4
  }

  var fieldGutter: CGFloat {
    16
  }

  var buttonGutter: CGFloat {
    16
  }

  var fieldHeight: CGFloat {
    44
  }

  var addSymbolName: String {
    "plus"
  }
}

#if DEBUG
  #Preview {
    RecipeIngredientEntry(
      placeholder: .RecipeSearch.recipeSearchSectionIncludePlaceholder,
      fieldAccessibilityIdentifier: RecipeSearchAccessibilityID.includeField,
      addAccessibilityIdentifier: RecipeSearchAccessibilityID.includeAddButton,
      onAdd: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
