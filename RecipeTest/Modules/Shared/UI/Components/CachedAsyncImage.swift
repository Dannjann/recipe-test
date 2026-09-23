//
//  CachedAsyncImage.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Kingfisher
import SwiftUI

/// A remote image backed by Kingfisher's download and disk cache.
///
/// Deliberately *not* named `AsyncImage`: SwiftUI ships a type by that name, and shadowing
/// it would silently change what `AsyncImage(url:)` means everywhere in the module.
///
/// ```swift
/// CachedAsyncImage(url: item.imageURL)
///   .aspectRatio(contentMode: .fill)
/// ```
struct CachedAsyncImage<Placeholder: View>: View {
  let url: URL?
  var shouldForceRefresh: Bool = false
  var maxRetryCount: Int = 3
  var retryInterval: TimeInterval = 5

  @ViewBuilder let placeholder: () -> Placeholder

  var body: some View {
    KFImage(url)
      .retry(maxCount: maxRetryCount, interval: .seconds(retryInterval))
      .forceRefresh(shouldForceRefresh)
      .placeholder(placeholder)
      .resizable()
  }
}

// MARK: - Default placeholder

/// Concrete `ProgressView`, not `AnyView`: type erasure in a view hierarchy costs SwiftUI
/// the structural information it uses to skip unchanged subtrees.
extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
  /// Uses a centred `ProgressView` while the image loads.
  init(url: URL?, shouldForceRefresh: Bool = false) {
    self.init(
      url: url,
      shouldForceRefresh: shouldForceRefresh,
      placeholder: { ProgressView() }
    )
  }
}

// MARK: - Previews

#if DEBUG

  #Preview("Placeholder — unreachable URL") {
    CachedAsyncImage(url: URL(string: "https://api.example.com/missing.png"))
      .frame(width: 120, height: 120)
  }

#endif
