//
//  IngredientChecklistRow.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// The strikethrough is decoration; `.isToggle` and the accessibility value are what
/// actually tell a VoiceOver reader whether the ingredient has been gathered.
struct IngredientChecklistRow: View {
  let ingredient: RecipeIngredient
  let isChecked: Bool
  let onTap: SingleResult<String>

  var body: some View {
    Button(
      action: { onTap(ingredient.id) },
      label: {
        HStack(
          alignment: .top,
          spacing: spacing
        ) {
          checkbox

          label

          Spacer(minLength: 0)
        }
        .padding(
          .horizontal,
          horizontalPadding
        )
        .padding(
          .vertical,
          verticalPadding
        )
        .frame(
          maxWidth: .infinity,
          alignment: .leading
        )
        .background(
          Color.themeColor(.surfacesBackground3),
          in: .rect(cornerRadius: cornerRadius)
        )
      }
    )
    .buttonStyle(.plain)
    .accessibilityAddTraits(.isToggle)
    .accessibilityValue(Text(
      isChecked
        ? .RecipeDetail.recipeDetailIngredientGathered
        : .RecipeDetail.recipeDetailIngredientNotGathered
    ))
  }
}

// MARK: - Getters

extension IngredientChecklistRow {
  static var baseBoxSize: CGFloat {
    24
  }
}

private extension IngredientChecklistRow {
  var spacing: CGFloat {
    14
  }

  var horizontalPadding: CGFloat {
    16
  }

  var verticalPadding: CGFloat {
    14
  }

  var cornerRadius: CGFloat {
    20
  }

  var boxCornerRadius: CGFloat {
    8
  }

  var borderWidth: CGFloat {
    1.5
  }
}

// MARK: - Subviews

private extension IngredientChecklistRow {
  var checkbox: some View {
    RoundedRectangle(cornerRadius: boxCornerRadius)
      .fill(Color.themeColor(isChecked ? .textPrimary : .surfacesBackground2))
      .overlay {
        RoundedRectangle(cornerRadius: boxCornerRadius)
          .strokeBorder(
            Color.themeColor(.textPrimary),
            lineWidth: borderWidth
          )
      }
      .overlay {
        Image(systemName: "checkmark")
          .themeTextStyle(.captionBold)
          .foregroundStyle(.themeColor(.textWhite))
          .opacity(isChecked ? 1 : 0)
      }
      .frame(
        width: Self.baseBoxSize,
        height: Self.baseBoxSize
      )
  }

  var label: some View {
    labelText
      .themeColor(isChecked ? .textSecondary : .textPrimary)
      .strikethrough(isChecked)
      .multilineTextAlignment(.leading)
  }

  /// The quantity and the name as one run-styled `Text` rather than two views: they have
  /// to wrap as a single paragraph, which an `HStack` of two `Text`s will not do.
  var labelText: Text {
    guard !ingredient.quantityText.isEmpty else {
      return Text(nameText)
    }

    return Text(quantityText + separatorText + nameText)
  }

  var quantityText: AttributedString {
    var text = AttributedString(ingredient.quantityText)
    text.font = .themeTextStyle(.bodyBold)

    return text
  }

  var separatorText: AttributedString {
    var text = AttributedString(" ")
    text.font = .themeTextStyle(.bodyRegular)

    return text
  }

  var nameText: AttributedString {
    var text = AttributedString(ingredient.name)
    text.font = .themeTextStyle(.bodyRegular)

    return text
  }
}

#if DEBUG
  #Preview("Not gathered") {
    IngredientChecklistRow(
      ingredient: .dummy(),
      isChecked: false,
      onTap: { _ in }
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Gathered") {
    IngredientChecklistRow(
      ingredient: .dummy(),
      isChecked: true,
      onTap: { _ in }
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("No quantity") {
    IngredientChecklistRow(
      ingredient: .dummy(
        quantityText: "",
        name: "Black Pepper"
      ),
      isChecked: false,
      onTap: { _ in }
    )
    .padding(20)
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
