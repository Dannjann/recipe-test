//
//  SectionState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// `.empty` is distinct from `.loaded([])`: zero rows has its own copy.
/// `.failed` carries only the detail worth adding to the generic heading, so the view renders
/// what it is given rather than deciding what to suppress.
nonisolated enum SectionState<Value: Equatable>: Equatable {
  case loading
  case loaded(Value)
  case empty
  case failed(String?)
}

// MARK: - Getters

nonisolated extension SectionState {
  var value: Value? {
    guard case let .loaded(value) = self else { return nil }

    return value
  }

  var isLoaded: Bool {
    value != nil
  }
}

// MARK: - Transitions

nonisolated extension SectionState {
  /// A refresh keeps its content; only a section with nothing to show becomes a spinner.
  var refreshing: SectionState {
    isLoaded ? self : .loading
  }

  /// Applied to the state as it was *before* the load began.
  ///
  /// SwiftUI cancels `.task` on disappear; that must not paint an error, and must not
  /// strand the section on the spinner `refreshing` just put there either.
  func recovering(from error: any Error) -> SectionState {
    guard !error.isCancellation else { return self }

    return .failed(Self.failureDetail(for: error))
  }
}

// MARK: - Helpers

private nonisolated extension SectionState {
  /// `AppError.unknown` describes itself with the generic heading, so passing it on as a
  /// detail would print the same sentence twice.
  static func failureDetail(for error: any Error) -> String? {
    let description = error.localizedDescription

    guard description != String(localized: .Shared.sharedErrorSomethingWentWrong) else {
      return nil
    }

    return description
  }
}

// MARK: - Collections

nonisolated extension SectionState where Value: Collection {
  /// Zero rows is `.empty`, never `.loaded([])`.
  static func rows(_ value: Value) -> SectionState {
    value.isEmpty ? .empty : .loaded(value)
  }
}
