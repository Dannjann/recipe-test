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
