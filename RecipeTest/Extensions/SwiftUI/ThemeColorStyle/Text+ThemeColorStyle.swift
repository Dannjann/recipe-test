//
//  Text+ThemeColorStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2025 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

/// replicate SwiftUI `font(_ font: Font?) -> Text`
extension Text {
  func themeColor(_ colorStyle: Color.ThemeColor) -> Text {
    foregroundStyle(Color.themeColor(colorStyle))
  }
}

#if DEBUG

  #Preview {
    Form {
      Section("Text Colors") {
        Group {
          Text("Primary Text")
            .themeColor(.textPrimary)

          Text("Secondary Text")
            .themeColor(.textSecondary)

          Text("Tertiary Text")
            .themeColor(.textTertiary)

          Text("Disabled Text")
            .themeColor(.textDisabled)

          Text("Inverted Text")
            .themeColor(.textInverted)

          Text("White Text")
            .themeColor(.textWhite)

          Text("Brand Default Text")
            .themeColor(.textBrandDefault)
        }
      }

      Section("Surface Colors") {
        Group {
          Text("Background")
            .themeColor(.surfacesBackground)

          Text("Background 2")
            .themeColor(.surfacesBackground2)

          Text("Background 3")
            .themeColor(.surfacesBackground3)

          Text("Fields and Tags")
            .themeColor(.surfacesFieldsAndTags)

          Text("Disabled Surface")
            .themeColor(.surfacesDisabled)

          Text("Inverted Surface")
            .themeColor(.surfacesInverted)

          Text("Brand Default Surface")
            .themeColor(.surfacesBrandDefault)

          Text("Brand Shade 1")
            .themeColor(.surfacesBrandShade1)

          Text("Brand Shade 2")
            .themeColor(.surfacesBrandShade2)

          Text("Brand Shade 3")
            .themeColor(.surfacesBrandShade3)
        }
      }

      Section("Border Colors") {
        Group {
          Text("Default Border")
            .themeColor(.bordersDefault)

          Text("Disabled Border")
            .themeColor(.bordersDisabled)

          Text("Secondary Border")
            .themeColor(.bordersSecondary)

          Text("Brand Default Border")
            .themeColor(.bordersBrandDefault)

          Text("Inverted Border")
            .themeColor(.bordersInverted)
        }
      }

      Section("Icon Colors") {
        Group {
          Text("Default Icons")
            .themeColor(.iconsDefault)

          Text("Secondary Icons")
            .themeColor(.iconsSecondary)

          Text("Tertiary Icons")
            .themeColor(.iconsTertiary)

          Text("Disabled Icons")
            .themeColor(.iconsDisabled)

          Text("Inverted Icons")
            .themeColor(.iconsInverted)

          Text("White Icons")
            .themeColor(.iconsWhite)

          Text("Brand Default Icons")
            .themeColor(.iconsBrandDefault)
        }
      }

      Section("Complementary Colors") {
        Group {
          Text("Complementary Default")
            .themeColor(.complementaryDefault)

          Text("Complementary Shade 1")
            .themeColor(.complementaryShade1)

          Text("Complementary Shade 2")
            .themeColor(.complementaryShade2)

          Text("Complementary Shade 3")
            .themeColor(.complementaryShade3)
        }
      }

      Section("Semantic Colors") {
        Group {
          Text("Success Default")
            .themeColor(.semanticsSuccessDefault)

          Text("Success Shade")
            .themeColor(.semanticsSuccessShade)

          Text("Info Default")
            .themeColor(.semanticsInfoDefault)

          Text("Info Shade")
            .themeColor(.semanticsInfoShade)

          Text("Warning Default")
            .themeColor(.semanticsWarningDefault)

          Text("Warning Shade")
            .themeColor(.semanticsWarningShade)

          Text("Error Default")
            .themeColor(.semanticsErrorDefault)

          Text("Error Shade")
            .themeColor(.semanticsErrorShade)
        }
      }
    }
  }

#endif
