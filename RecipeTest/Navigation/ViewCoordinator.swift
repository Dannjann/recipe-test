//
//  ViewCoordinator.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2024 Danjan. All rights reserved.
//

import SwiftUI

/// In SwiftUI a coordinator *is* a view: it owns a flow's destinations and wires each
/// screen's callbacks to a `PathRouter` push. The alias exists so a type's role is
/// visible at its declaration — `struct RecipeViewCoordinator: ViewCoordinator` says more
/// than `: View`.
typealias ViewCoordinator = View
