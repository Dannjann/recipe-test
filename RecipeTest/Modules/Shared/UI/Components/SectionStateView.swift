//
//  SectionStateView.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import SwiftUI

/// Renders the three states a section can be in that are not its content, and hands the
/// fourth to its caller.
///
/// `minHeight` holds the section's footprint across all four cases, so the page below it
/// does not jump as each section resolves at its own pace.
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
        .frame(maxWidth: .infinity, minHeight: minHeight)

    case let .loaded(value):
      content(value)

    case .empty:
      message(title: Text(emptyMessage), description: nil, showsRetry: false)

    case let .failed(description):
      message(
        title: Text(String(localized: .Shared.sharedErrorSomethingWentWrong)),
        description: Text(description),
        showsRetry: true
      )
    }
  }
}

// MARK: - Subviews

private extension SectionStateView {
  func message(title: Text, description: Text?, showsRetry: Bool) -> some View {
    VStack(spacing: 12) {
      title
        .themeTextStyle(.bodyBold)
        .themeColor(.textPrimary)

      if let description {
        description
          .themeTextStyle(.subheadlineRegular)
          .themeColor(.textSecondary)
          .multilineTextAlignment(.center)
      }

      if showsRetry {
        Button(String(localized: .Shared.sharedRetry), action: onRetryTap)
          .themeTextStyle(.bodyBold)
          .foregroundStyle(.themeColor(.textBrandDefault))
      }
    }
    .frame(maxWidth: .infinity, minHeight: minHeight)
    .padding(.horizontal, 20)
  }
}

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

#Preview("Failed") {
  SectionStateView(
    state: SectionState<[String]>.failed("The request timed out."),
    minHeight: 240,
    emptyMessage: "Nothing here yet",
    onRetryTap: {},
    content: { Text($0.joined()) }
  )
}
