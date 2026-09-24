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
///   .scaledToFill()
/// ```
struct CachedAsyncImage<Placeholder: View>: View {
  let url: URL?
  var forceRefresh: Bool = false
  var maxRetryCount: Int = 3
  var retryInterval: TimeInterval = 5

  @ViewBuilder let placeholder: () -> Placeholder

  var body: some View {
    KFImage(url)
      .retry(maxCount: maxRetryCount, interval: .seconds(retryInterval))
      .forceRefresh(forceRefresh)
      .placeholder(placeholder)
      .resizable()
  }
}

// MARK: - Default placeholder

extension CachedAsyncImage where Placeholder == AnyView {
  /// Uses a centred `ProgressView` while the image loads.
  init(url: URL?, forceRefresh: Bool = false) {
    self.init(
      url: url,
      forceRefresh: forceRefresh,
      placeholder: { AnyView(ProgressView()) }
    )
  }
}

#Preview("Placeholder — unreachable URL") {
  CachedAsyncImage(url: URL(string: "https://api.example.com/missing.png"))
    .frame(width: 120, height: 120)
}
