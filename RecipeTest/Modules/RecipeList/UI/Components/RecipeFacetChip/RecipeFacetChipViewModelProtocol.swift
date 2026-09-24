//
//  RecipeFacetChipViewModelProtocol.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2026 Danjan. All rights reserved.
//

import Foundation

nonisolated protocol RecipeFacetChipViewModelProtocol: Identifiable {
  var id: RecipeQueryFacet { get }
  var label: String { get }
  var removeAccessibilityLabel: String { get }

  /// The prototype tints an excluded ingredient differently. A presentation fact the view
  /// model owns, so the chip branches on a flag rather than inspecting the facet.
  var isExclusion: Bool { get }
}
