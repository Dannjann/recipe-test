//
//  SectionState.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// What one section of a screen currently has to show.
///
/// A screen whose sections are fed by separate requests needs this per section rather
/// than once for the whole screen: a categories outage should cost the categories grid
/// and nothing else.
///
/// `.empty` is deliberately distinct from `.loaded([])`. Zero rows is a legitimate answer
/// with its own copy, and a view that has to ask `isEmpty` to decide which of two things
/// to draw has the state machine in the wrong place.
///
/// `failed` carries the message rather than the `Error` so the enum stays `Equatable` and
/// a test can assert on what the reader is actually shown.
nonisolated enum SectionState<Value: Equatable>: Equatable {
  case loading
  case loaded(Value)
  case empty
  case failed(String)
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
