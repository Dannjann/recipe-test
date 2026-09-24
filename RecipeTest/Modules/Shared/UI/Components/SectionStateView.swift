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
        .frame(maxWidth: .infinity, minHeight: minHeight)

    case let .loaded(value):
      content(value)

    case .empty:
      message(title: Text(emptyMessage), description: nil, showsRetry: false)

    case let .failed(description):
      failure(description: description)
    }
  }
}

// MARK: - Subviews

private extension SectionStateView {
  /// `AppError.unknown` describes itself with the heading, so printing both repeats a sentence.
  func failure(description: String) -> some View {
    let heading = String(localized: .Shared.sharedErrorSomethingWentWrong)

    return message(
      title: Text(heading),
      description: description == heading ? nil : Text(description),
      showsRetry: true
    )
  }

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
