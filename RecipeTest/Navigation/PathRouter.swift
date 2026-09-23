//
//  PathRouter.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import SwiftUI

@Observable
final class PathRouter: PathRouterProtocol {
  var path: NavigationPath = .init()

  /// Mirrors `path`, which can be counted but not read back — `NavigationPath` erases what
  /// it holds. `pop(to:)` needs the values, so they are kept alongside.
  ///
  /// The mirror is never trusted: the user pops `path` directly every time they swipe back
  /// or tap a nav bar's Back button, and a `NavigationLink(value:)` appends to it. Every
  /// method calls `resyncWithPath()` first and guards against `path` itself, so a stale
  /// mirror degrades `pop(to:)` rather than trapping on an empty path.
  private var routes: [AnyHashable] = []
}

// MARK: - Methods

extension PathRouter {
  func setRoot(to view: some Hashable) {
    path = .init()
    routes = []

    push(view)
  }

  func push(_ view: some Hashable) {
    path.append(view)
    routes.append(AnyHashable(view))
  }

  func pop() {
    resyncWithPath()
    guard !path.isEmpty else { return }

    path.removeLast()
    if !routes.isEmpty {
      routes.removeLast()
    }
  }

  /// Pops back to `view`, leaving it on top of the stack. No-op if it is not on the stack
  /// or is already the topmost entry.
  func pop(to view: some Hashable) {
    resyncWithPath()

    guard
      let index = routes.lastIndex(of: AnyHashable(view)),
      case let depth = routes.count - (index + 1),
      depth > 0,
      depth <= path.count
    else { return }

    path.removeLast(depth)
    routes.removeLast(depth)
  }

  func popToRoot() {
    path = .init()
    routes = []
  }

  func replaceLast(with view: some Hashable) {
    pop()
    push(view)
  }
}

// MARK: - Helpers

private extension PathRouter {
  /// Drops mirror entries for destinations the user already popped.
  ///
  /// Only ever truncates. If `path` is *longer* than the mirror something appended
  /// outside the router and those values are unrecoverable — `pop(to:)` is then limited to
  /// what the mirror still knows, which is why it bounds its removal by `path.count`.
  func resyncWithPath() {
    guard routes.count > path.count else { return }

    routes.removeLast(routes.count - path.count)
  }
}
