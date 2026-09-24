//
//  RecipeServingsPicker.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeServingsPicker: View {
  let options: [RecipeServingsOptionViewModel]
  let onSelect: SingleResult<RecipeServings>

  @ScaledMetric(relativeTo: .body) private var optionSize: CGFloat = RecipeServingsPicker.baseOptionSize

  var body: some View {
    // Scrolls rather than compressing: `optionSize` scales with the body metric, so at
    // accessibility sizes four options plus their gutters exceed the card's width and a plain
    // `HStack` would push "6+" off the screen with no way to reach it.
    ScrollView(.horizontal) {
      HStack(spacing: contentSpacing) {
        ForEach(options) { option in
          Button(
            action: { onSelect(option.id) },
            label: {
              Text(option.label)
                .themeTextStyle(.bodyBold)
                .themeColor(option.labelColorStyle)
                .frame(
                  minWidth: optionSize,
                  minHeight: optionSize
                )
                .padding(
                  .horizontal,
                  horizontalGutter
                )
                .background(
                  Color.themeColor(option.backgroundColorStyle),
                  in: .capsule
                )
                .contentShape(.capsule)
            }
          )
          .buttonStyle(.plain)
          .accessibilityIdentifier(option.accessibilityIdentifier)
          .accessibilityLabel(Text(option.accessibilityLabel))
          .accessibilityAddTraits(option.isSelected ? [.isButton, .isSelected] : .isButton)
        }
      }
    }
    .scrollIndicators(.hidden)
  }
}

// MARK: - Getters

extension RecipeServingsPicker {
  static var baseOptionSize: CGFloat {
    44
  }
}

// MARK: - Getters > Constants

private extension RecipeServingsPicker {
  var contentSpacing: CGFloat {
    8
  }

  var horizontalGutter: CGFloat {
    8
  }
}

#if DEBUG
  #Preview("Nothing selected") {
    RecipeServingsPicker(
      options: RecipeServings.allCases.map {
        RecipeServingsOptionViewModel(
          servings: $0,
          isSelected: false
        )
      },
      onSelect: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }

  #Preview("Four selected") {
    RecipeServingsPicker(
      options: RecipeServings.allCases.map {
        RecipeServingsOptionViewModel(
          servings: $0,
          isSelected: $0 == .four
        )
      },
      onSelect: { _ in }
    )
    .padding()
    .background(Color.themeColor(.surfacesBackground2))
  }
#endif
