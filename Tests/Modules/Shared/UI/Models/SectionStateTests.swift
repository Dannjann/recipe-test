//
//  SectionStateTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

struct SectionStateTests {
  @Test
  func refreshing_onALoadedSection_keepsItsContent() {
    let state = SectionState<[String]>.loaded(["a"])

    let refreshed = state.refreshing

    #expect(refreshed == .loaded(["a"]))
  }

  @Test
  func refreshing_onAFailedSection_becomesLoading() {
    let state = SectionState<[String]>.failed("The request timed out.")

    let refreshed = state.refreshing

    #expect(refreshed == .loading)
  }

  @Test
  func rows_withNoRows_isEmptyRatherThanAnEmptyLoad() {
    let state = SectionState<[String]>.rows([])

    #expect(state == .empty)
  }

  @Test
  func rows_withRows_isLoaded() {
    let state = SectionState<[String]>.rows(["a"])

    #expect(state == .loaded(["a"]))
  }

  @Test
  func recovering_fromACancellation_keepsThePreviousState() {
    let previous = SectionState<[String]>.loaded(["a"])

    let recovered = previous.recovering(from: CancellationError())

    #expect(recovered == .loaded(["a"]))
  }

  @Test
  func recovering_fromACancelledURLError_keepsThePreviousState() {
    let previous = SectionState<[String]>.loaded(["a"])
    let error = URLError(.cancelled)

    let recovered = previous.recovering(from: error)

    #expect(recovered == .loaded(["a"]))
  }

  @Test
  func recovering_fromARealError_failsWithItsDescription() {
    let previous = SectionState<[String]>.loading
    let error = URLError(.notConnectedToInternet)

    let recovered = previous.recovering(from: error)

    #expect(recovered == .failed(error.localizedDescription))
  }

  @Test
  func recovering_fromAnErrorDescribedByTheGenericHeading_carriesNoDetail() {
    let previous = SectionState<[String]>.loading

    let recovered = previous.recovering(from: AppError.unknown)

    #expect(recovered == .failed(nil))
  }
}
