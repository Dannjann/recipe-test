//
//  SectionStateView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// `minHeight` holds the section's footprint so the page below does not jump as it resolves.
struct SectionStateView<Value: Equatable, Content: View>: View {
  let state: SectionState<Value>
  let minHeight: CGFloat
  let emptyMessage: LocalizedStringResource
  let onRetryTap: VoidResult

  @ViewBuilder let content: (Value) -> Content

  var body: some View {
    switch state {
    case .loading:
      ProgressView()
        .tint(.themeColor(.iconsBrandDefault))
        .frame(
          maxWidth: .infinity,
          minHeight: minHeight
        )

    case let .loaded(value):
      content(value)

    case .empty:
      message(
        title: Text(emptyMessage),
        detail: nil,
        showsRetry: false
      )

    case let .failed(detail):
      message(
        title: Text(.Shared.sharedErrorSomethingWentWrong),
        detail: detail.map { Text($0) },
        showsRetry: true
      )
    }
  }
}

// MARK: - Getters

private extension SectionStateView {
  var contentSpacing: CGFloat {
    12
  }

  var horizontalGutter: CGFloat {
    20
  }
}

// MARK: - Subviews

private extension SectionStateView {
  func message(
    title: Text,
    detail: Text?,
    showsRetry: Bool
  ) -> some View {
    VStack(spacing: contentSpacing) {
      title
        .themeTextStyle(.bodyBold)
        .themeColor(.textPrimary)

      if let detail {
        detail
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if showsRetry {
        Button(
          action: onRetryTap,
          label: { Text(.Shared.sharedRetry) }
        )
        .themeTextStyle(.bodyBold)
        .foregroundStyle(.themeColor(.textBrandDefault))
      }
    }
    .frame(
      maxWidth: .infinity,
      minHeight: minHeight
    )
    .padding(
      .horizontal,
      horizontalGutter
    )
  }
}

#if DEBUG
  #Preview("Loading") {
    SectionStateView(
      state: SectionState<[String]>.loading,
      minHeight: 240,
      emptyMessage: "Nothing here yet",
      onRetryTap: {},
      content: { Text($0.joined()) }
    )
  }

  #Preview("Empty") {
    SectionStateView(
      state: SectionState<[String]>.empty,
      minHeight: 240,
      emptyMessage: "Nothing here yet",
      onRetryTap: {},
      content: { Text($0.joined()) }
    )
  }

  #Preview("Failed with detail") {
    SectionStateView(
      state: SectionState<[String]>.failed("The request timed out."),
      minHeight: 240,
      emptyMessage: "Nothing here yet",
      onRetryTap: {},
      content: { Text($0.joined()) }
    )
  }

  #Preview("Failed without detail") {
    SectionStateView(
      state: SectionState<[String]>.failed(nil),
      minHeight: 240,
      emptyMessage: "Nothing here yet",
      onRetryTap: {},
      content: { Text($0.joined()) }
    )
  }
#endif
