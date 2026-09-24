//
//  RecipeGallery.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Pages one photograph at a time. `urls` is allowed to be empty: a recipe with no
/// photograph anywhere shows the placeholder fill at full height rather than collapsing
/// and pulling the sheet up over the top bar.
struct RecipeGallery: View {
  let urls: [URL]
  let accessibilityTitle: String

  @ScaledMetric(relativeTo: .body) private var height: CGFloat = RecipeGallery.baseHeight

  @State private var scrolledIndex: Int?

  var body: some View {
    content
      .frame(height: height)
      .overlay(alignment: .bottom) { dots }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(accessibilityTitle))
      .accessibilityValue(Text(.RecipeDetail.recipeDetailGalleryPhotoPosition(
        activeIndex + 1,
        max(
          urls.count,
          1
        )
      )))
  }
}

// MARK: - Getters

extension RecipeGallery {
  static var baseHeight: CGFloat {
    380
  }
}

private extension RecipeGallery {
  var activeIndex: Int {
    scrolledIndex ?? 0
  }

  var dotsBottomInset: CGFloat {
    48
  }
}

// MARK: - Subviews

private extension RecipeGallery {
  @ViewBuilder
  var content: some View {
    if urls.isEmpty {
      Color.themeColor(.surfacesBackground3)
    } else {
      photographs
    }
  }

  var photographs: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
        ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
          CachedAsyncImage(url: url) {
            Color.themeColor(.surfacesBackground3)
          }
          .aspectRatio(contentMode: .fill)
          .containerRelativeFrame(.horizontal)
          .frame(height: height)
          .clipped()
          .id(index)
        }
      }
      .scrollTargetLayout()
    }
    .scrollIndicators(.hidden)
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $scrolledIndex)
  }

  @ViewBuilder
  var dots: some View {
    if urls.count > 1 {
      RecipeGalleryDots(
        count: urls.count,
        activeIndex: activeIndex
      )
      .padding(
        .bottom,
        dotsBottomInset
      )
    }
  }
}

#if DEBUG
  #Preview("Three photographs") {
    RecipeGallery(
      urls: Recipe.dummy().gallery,
      accessibilityTitle: "Spaghetti alla Carbonara"
    )
  }

  #Preview("No photographs") {
    RecipeGallery(
      urls: [],
      accessibilityTitle: "Spaghetti alla Carbonara"
    )
  }
#endif
