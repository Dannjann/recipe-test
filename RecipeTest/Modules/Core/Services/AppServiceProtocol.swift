//
//  AppServiceProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2020 Danjan. All rights reserved.
//

import Foundation

/// Marks a type as one of the app's long-lived services, held by `AppContainer` and
/// injected into view models through `init`.
nonisolated protocol AppServiceProtocol: AnyObject {}
