//
//  MockRecipeFilter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

/// Stands in for the backend's query engine over one request's query string.
///
/// Parsed once per request so the predicates below read as predicates rather than as
/// repeated query-string digging. A parameter this does not recognise is ignored rather
/// than treated as "match nothing" — an unknown parameter must never silently empty a
/// screen.
///
/// `sort=latest` needs no branch: the fixture is already stored newest-first, so accepting
/// and ignoring it is the correct behaviour.
nonisolated struct MockRecipeFilter {
  private let category: String?
  private let cuisine: String?
  private let isVegetarian: Bool?
  private let servings: String?
  private let includedIngredients: [String]
  private let excludedIngredients: [String]
  private let searchText: String?
  private let searchesSteps: Bool

  init(url: URL) {
    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

    func values(_ name: String) -> [String] {
      items.filter { $0.name == name }.compactMap(\.value).filter { !$0.isEmpty }
    }

    category = values("category").first
    cuisine = values("cuisine").first
    isVegetarian = values("is_vegetarian").first.flatMap(Self.flag)
    servings = values("servings").first
    includedIngredients = values("include_ingredients")
    excludedIngredients = values("exclude_ingredients")
    searchText = values("search_text").first
    searchesSteps = values("searches_steps").first.flatMap(Self.flag) ?? false
  }

  /// Accepts both spellings a URL encoder might produce, and returns nil for anything
  /// else — an unrecognised *value* must be ignored like an unrecognised parameter, not
  /// silently become a filter for the opposite rows.
  private static func flag(_ value: String) -> Bool? {
    switch value.lowercased() {
    case "true", "1":
      true

    case "false", "0":
      false

    default:
      nil
    }
  }
}

// MARK: - Methods

nonisolated extension MockRecipeFilter {
  func matches(_ row: [String: Any]) -> Bool {
    matchesFacets(row) && matchesIngredients(row) && matchesSearch(row)
  }
}

// MARK: - Getters > Constants

private nonisolated extension MockRecipeFilter {
  /// The prototype's serving filter offers 1, 2, 4 and "6+"; the last is a lower bound.
  static var servingsLowerBoundMarker: String {
    "6+"
  }

  static var servingsLowerBound: Int {
    6
  }
}

// MARK: - Matching

private nonisolated extension MockRecipeFilter {
  func matchesFacets(_ row: [String: Any]) -> Bool {
    if let category, !equals(row["category"], expected: category) {
      return false
    }

    if let cuisine, !equals(row["cuisine"], expected: cuisine) {
      return false
    }

    if let isVegetarian, row["is_vegetarian"] as? Bool != isVegetarian {
      return false
    }

    if let servings, !matchesServings(row, expected: servings) {
      return false
    }

    return true
  }

  /// The prototype's fourth serving option is a bound rather than a value, so it is
  /// matched separately. A value that is neither the bound nor a number is ignored — the
  /// same promise this type makes about an unrecognised parameter name.
  func matchesServings(_ row: [String: Any], expected servings: String) -> Bool {
    let count = row["servings"] as? Int ?? 0

    if servings == Self.servingsLowerBoundMarker {
      return count >= Self.servingsLowerBound
    }

    guard let wanted = Int(servings) else {
      return true
    }

    return count == wanted
  }

  /// Every included term must appear, and no excluded term may.
  func matchesIngredients(_ row: [String: Any]) -> Bool {
    guard !includedIngredients.isEmpty || !excludedIngredients.isEmpty else {
      return true
    }

    let names = ingredientNames(in: row)

    func mentions(_ term: String) -> Bool {
      names.contains { $0.contains(fold(term)) }
    }

    return includedIngredients.allSatisfy(mentions)
      && !excludedIngredients.contains(where: mentions)
  }

  func matchesSearch(_ row: [String: Any]) -> Bool {
    guard let search = searchText.map(fold) else {
      return true
    }

    var haystack = ["title", "description", "category", "cuisine"]
      .compactMap { row[$0] as? String }
      .map(fold)

    haystack += ingredientNames(in: row)

    if searchesSteps {
      haystack += (row["steps"] as? [String] ?? []).map(fold)
    }

    return haystack.contains { $0.contains(search) }
  }

  func ingredientNames(in row: [String: Any]) -> [String] {
    (row["ingredients"] as? [[String: Any]] ?? [])
      .compactMap { $0["name"] as? String }
      .map(fold)
  }

  func equals(_ stored: Any?, expected wanted: String) -> Bool {
    (stored as? String).map { fold($0) == fold(wanted) } ?? false
  }

  /// Case- and diacritic-insensitive, so `jamon` finds `jamón`.
  ///
  /// Deliberately locale-independent: under a Turkish locale `.current` would fold `I` to
  /// a dotless `ı`, and a search for `Italian` would stop matching `italian`.
  func fold(_ value: String) -> String {
    value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
  }
}
