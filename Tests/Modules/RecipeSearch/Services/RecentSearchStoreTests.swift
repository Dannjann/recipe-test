//
//  RecentSearchStoreTests.swift
//  Tests
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation
@testable import RecipeTest
import Testing

@MainActor
struct RecentSearchStoreTests {
  @Test
  func record_twoTerms_ordersMostRecentFirst() {
    let store = makeStore()

    store.record("pho")
    store.record("adobo")

    #expect(store.searches == ["adobo", "pho"])
  }

  @Test
  func record_aTermAlreadyStored_movesItToTheFrontWithoutDuplicating() {
    let store = makeStore()

    store.record("pho")
    store.record("adobo")
    store.record("PHO")

    #expect(store.searches == ["PHO", "adobo"])
  }

  @Test
  func record_blankTerms_storesNothing() {
    let store = makeStore()

    store.record("   ")
    store.record("")

    #expect(store.searches.isEmpty)
  }

  @Test
  func record_paddedTerm_storesItTrimmed() {
    let store = makeStore()

    store.record("  adobo  ")

    #expect(store.searches == ["adobo"])
  }

  @Test
  func record_moreThanTheLimit_keepsTheTenMostRecent() {
    let store = makeStore()

    for index in 1 ... 12 {
      store.record("term-\(index)")
    }

    #expect(store.searches.count == 10)
    #expect(store.searches.first == "term-12")
    #expect(!store.searches.contains("term-1"))
    #expect(!store.searches.contains("term-2"))
  }

  @Test
  func clear_afterRecording_emptiesTheList() {
    let store = makeStore()
    store.record("adobo")

    store.clear()

    #expect(store.searches.isEmpty)
  }

  @Test
  func searches_aSecondStoreOverTheSameDefaults_readsBackWhatTheFirstWrote() {
    let defaults = makeDefaults()
    RecentSearchStore(defaults: defaults).record("adobo")

    #expect(RecentSearchStore(defaults: defaults).searches == ["adobo"])
  }
}

// MARK: - Helpers

private extension RecentSearchStoreTests {
  /// A throwaway suite per store: `.standard` would leak one test's terms into the next, and
  /// into whatever is installed on the machine running them.
  func makeDefaults() -> UserDefaults {
    let suiteName = "RecentSearchStoreTests.\(UUID().uuidString)"

    guard let defaults = UserDefaults(suiteName: suiteName) else {
      fatalError("Could not open a UserDefaults suite for the test")
    }

    return defaults
  }

  func makeStore() -> RecentSearchStore {
    RecentSearchStore(defaults: makeDefaults())
  }
}
