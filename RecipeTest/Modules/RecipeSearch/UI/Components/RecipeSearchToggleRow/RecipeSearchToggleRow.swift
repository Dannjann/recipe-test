//
//  RecipeSearchToggleRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeSearchToggleRow: View {
  let title: LocalizedStringResource
  let detail: LocalizedStringResource
  let isOn: Bool
  let accessibilityIdentifier: String
  let onToggle: VoidResult

  var body: some View {
    Toggle(
      isOn: binding,
      label: {
        VStack(
          alignment: .leading,
          spacing: contentSpacing
        ) {
          Text(title)
            .themeTextStyle(.bodyBold)
            .themeColor(.textPrimary)

          Text(detail)
            .themeTextStyle(.footnoteRegular)
            .themeColor(.textSecondary)
        }
      }
    )
    .tint(.themeColor(.surfacesBrandDefault))
    .accessibilityIdentifier(accessibilityIdentifier)
  }
}

// MARK: - Getters

private extension RecipeSearchToggleRow {
  /// Read-only with a callback, so the row keeps the project's callback style and no view
  /// needs `@Bindable` over an existential view model.
  var binding: Binding<Bool> {
    Binding(
      get: { isOn },
      set: { _ in onToggle() }
    )
  }
}

// MARK: - Getters > Constants

private extension RecipeSearchToggleRow {
  var contentSpacing: CGFloat {
    2
  }
}

#if DEBUG
  #Preview("Off") {
    RecipeSearchToggleRow(
      title: .RecipeSearch.recipeSearchSectionVegetarianTitle,
      detail: .RecipeSearch.recipeSearchSectionVegetarianDetail,
      isOn: false,
      accessibilityIdentifier: RecipeSearchAccessibilityID.vegetarianToggle,
      onToggle: {}
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("On") {
    RecipeSearchToggleRow(
      title: .RecipeSearch.recipeSearchSectionStepsTitle,
      detail: .RecipeSearch.recipeSearchSectionStepsDetail,
      isOn: true,
      accessibilityIdentifier: RecipeSearchAccessibilityID.stepsToggle,
      onToggle: {}
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
