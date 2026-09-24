//
//  RecipeInstructions.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeInstructions: View {
  let steps: [String]

  var body: some View {
    VStack(
      alignment: .leading,
      spacing: spacing
    ) {
      ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
        RecipeInstructionRow(
          number: index + 1,
          total: steps.count,
          text: step
        )
      }
    }
    .padding(
      .horizontal,
      horizontalPadding
    )
  }
}

// MARK: - Getters

private extension RecipeInstructions {
  var spacing: CGFloat {
    16
  }

  var horizontalPadding: CGFloat {
    20
  }
}

#if DEBUG
  #Preview {
    RecipeInstructions(steps: Recipe.dummy().steps)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .top
      )
      .background(Color.themeColor(.surfacesBackground2))
  }
#endif
