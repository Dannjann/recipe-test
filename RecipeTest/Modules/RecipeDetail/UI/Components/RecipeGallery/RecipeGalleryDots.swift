//
//  RecipeGalleryDots.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

struct RecipeGalleryDots: View {
  let count: Int
  let activeIndex: Int

  var body: some View {
    HStack(spacing: spacing) {
      ForEach(0 ..< count, id: \.self) { index in
        Capsule()
          .fill(Color.themeColor(.textWhite).opacity(index == activeIndex ? 1 : inactiveOpacity))
          .frame(
            width: index == activeIndex ? activeWidth : size,
            height: size
          )
      }
    }
    .animation(
      .snappy(duration: 0.2),
      value: activeIndex
    )
    .accessibilityHidden(true)
  }
}

// MARK: - Getters

private extension RecipeGalleryDots {
  var size: CGFloat {
    8
  }

  var activeWidth: CGFloat {
    24
  }

  var spacing: CGFloat {
    6
  }

  var inactiveOpacity: CGFloat {
    0.55
  }
}

#if DEBUG
  #Preview {
    RecipeGalleryDots(
      count: 3,
      activeIndex: 1
    )
    .padding(20)
    .background(Color.themeColor(.textPrimary))
  }
#endif
