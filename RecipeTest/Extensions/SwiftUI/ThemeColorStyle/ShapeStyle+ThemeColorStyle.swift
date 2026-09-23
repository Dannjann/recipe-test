//
//  ShapeStyle+ThemeColorStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2025 Danjan. All rights reserved.
//

import SwiftUI

extension ShapeStyle where Self == Color {
  static func themeColor(_ colorStyle: Color.ThemeColor) -> Color {
    Color.themeColor(colorStyle)
  }
}

#if DEBUG

  #Preview {
    ScrollView {
      LazyVStack(spacing: 20) {
        Section("Text Colors - Fill") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
            Circle()
              .fill(.themeColor(.textPrimary))
              .frame(width: 60, height: 60)
              .overlay(Text("Primary").font(.caption2).foregroundColor(.white))

            Circle()
              .fill(.themeColor(.textSecondary))
              .frame(width: 60, height: 60)
              .overlay(Text("Secondary").font(.caption2).foregroundColor(.white))

            Circle()
              .fill(.themeColor(.textTertiary))
              .frame(width: 60, height: 60)
              .overlay(Text("Tertiary").font(.caption2).foregroundColor(.white))

            Circle()
              .fill(.themeColor(.textDisabled))
              .frame(width: 60, height: 60)
              .overlay(Text("Disabled").font(.caption2).foregroundColor(.white))

            Circle()
              .fill(.themeColor(.textInverted))
              .frame(width: 60, height: 60)
              .overlay(Text("Inverted").font(.caption2).foregroundColor(.black))

            Circle()
              .fill(.themeColor(.textWhite))
              .frame(width: 60, height: 60)
              .overlay(Text("White").font(.caption2).foregroundColor(.black))

            Circle()
              .fill(.themeColor(.textBrandDefault))
              .frame(width: 60, height: 60)
              .overlay(Text("Brand").font(.caption2).foregroundColor(.white))
          }
        }

        Section("Text Colors - Stroke") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
            Circle()
              .stroke(.themeColor(.textPrimary), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("Primary").font(.caption2))

            Circle()
              .stroke(.themeColor(.textSecondary), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("Secondary").font(.caption2))

            Circle()
              .stroke(.themeColor(.textTertiary), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("Tertiary").font(.caption2))

            Circle()
              .stroke(.themeColor(.textDisabled), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("Disabled").font(.caption2))

            Circle()
              .stroke(.themeColor(.textInverted), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("Inverted").font(.caption2))

            Circle()
              .stroke(.themeColor(.textWhite), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("White").font(.caption2))

            Circle()
              .stroke(.themeColor(.textBrandDefault), lineWidth: 4)
              .frame(width: 60, height: 60)
              .overlay(Text("Brand").font(.caption2))
          }
        }

        Section("Surface Colors - Fill") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBackground))
              .frame(width: 80, height: 60)
              .overlay(Text("BG").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBackground2))
              .frame(width: 80, height: 60)
              .overlay(Text("BG2").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBackground3))
              .frame(width: 80, height: 60)
              .overlay(Text("BG3").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesFieldsAndTags))
              .frame(width: 80, height: 60)
              .overlay(Text("Fields").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesDisabled))
              .frame(width: 80, height: 60)
              .overlay(Text("Disabled").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesInverted))
              .frame(width: 80, height: 60)
              .overlay(Text("Inverted").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBrandDefault))
              .frame(width: 80, height: 60)
              .overlay(Text("Brand").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBrandShade1))
              .frame(width: 80, height: 60)
              .overlay(Text("Shade1").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBrandShade2))
              .frame(width: 80, height: 60)
              .overlay(Text("Shade2").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .fill(.themeColor(.surfacesBrandShade3))
              .frame(width: 80, height: 60)
              .overlay(Text("Shade3").font(.caption2))
          }
        }

        Section("Border Colors - Stroke") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
              .stroke(.themeColor(.bordersDefault), lineWidth: 4)
              .frame(width: 80, height: 60)
              .overlay(Text("Default").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .stroke(.themeColor(.bordersDisabled), lineWidth: 4)
              .frame(width: 80, height: 60)
              .overlay(Text("Disabled").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .stroke(.themeColor(.bordersSecondary), lineWidth: 4)
              .frame(width: 80, height: 60)
              .overlay(Text("Secondary").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .stroke(.themeColor(.bordersBrandDefault), lineWidth: 4)
              .frame(width: 80, height: 60)
              .overlay(Text("Brand").font(.caption2))

            RoundedRectangle(cornerRadius: 8)
              .stroke(.themeColor(.bordersInverted), lineWidth: 4)
              .frame(width: 80, height: 60)
              .overlay(Text("Inverted").font(.caption2))
          }
        }

        Section("Icon Colors - Fill") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
            Capsule()
              .fill(.themeColor(.iconsDefault))
              .frame(width: 80, height: 40)
              .overlay(Text("Default").font(.caption2).foregroundColor(.white))

            Capsule()
              .fill(.themeColor(.iconsSecondary))
              .frame(width: 80, height: 40)
              .overlay(Text("Secondary").font(.caption2).foregroundColor(.white))

            Capsule()
              .fill(.themeColor(.iconsTertiary))
              .frame(width: 80, height: 40)
              .overlay(Text("Tertiary").font(.caption2).foregroundColor(.white))

            Capsule()
              .fill(.themeColor(.iconsDisabled))
              .frame(width: 80, height: 40)
              .overlay(Text("Disabled").font(.caption2).foregroundColor(.white))

            Capsule()
              .fill(.themeColor(.iconsInverted))
              .frame(width: 80, height: 40)
              .overlay(Text("Inverted").font(.caption2).foregroundColor(.black))

            Capsule()
              .fill(.themeColor(.iconsWhite))
              .frame(width: 80, height: 40)
              .overlay(Text("White").font(.caption2).foregroundColor(.black))

            Capsule()
              .fill(.themeColor(.iconsBrandDefault))
              .frame(width: 80, height: 40)
              .overlay(Text("Brand").font(.caption2).foregroundColor(.white))
          }
        }

        Section("Complementary Colors - Fill & Stroke") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
            Rectangle()
              .fill(.themeColor(.complementaryDefault))
              .frame(width: 120, height: 60)
              .overlay(Text("Default Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.complementaryDefault), lineWidth: 4)
              .frame(width: 120, height: 60)
              .overlay(Text("Default Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.complementaryShade1))
              .frame(width: 120, height: 60)
              .overlay(Text("Shade 1 Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.complementaryShade1), lineWidth: 4)
              .frame(width: 120, height: 60)
              .overlay(Text("Shade 1 Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.complementaryShade2))
              .frame(width: 120, height: 60)
              .overlay(Text("Shade 2 Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.complementaryShade2), lineWidth: 4)
              .frame(width: 120, height: 60)
              .overlay(Text("Shade 2 Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.complementaryShade3))
              .frame(width: 120, height: 60)
              .overlay(Text("Shade 3 Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.complementaryShade3), lineWidth: 4)
              .frame(width: 120, height: 60)
              .overlay(Text("Shade 3 Stroke").font(.caption))
          }
        }

        Section("Semantic Colors - Fill & Stroke") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
            Rectangle()
              .fill(.themeColor(.semanticsSuccessDefault))
              .frame(width: 120, height: 50)
              .overlay(Text("Success Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.semanticsSuccessDefault), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Success Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsSuccessShade))
              .frame(width: 120, height: 50)
              .overlay(Text("Success Shade Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.semanticsSuccessShade), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Success Shade Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsInfoDefault))
              .frame(width: 120, height: 50)
              .overlay(Text("Info Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.semanticsInfoDefault), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Info Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsInfoShade))
              .frame(width: 120, height: 50)
              .overlay(Text("Info Shade Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.semanticsInfoShade), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Info Shade Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsWarningDefault))
              .frame(width: 120, height: 50)
              .overlay(Text("Warning Fill").font(.caption).foregroundColor(.black))

            Rectangle()
              .stroke(.themeColor(.semanticsWarningDefault), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Warning Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsWarningShade))
              .frame(width: 120, height: 50)
              .overlay(Text("Warning Shade Fill").font(.caption).foregroundColor(.black))

            Rectangle()
              .stroke(.themeColor(.semanticsWarningShade), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Warning Shade Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsErrorDefault))
              .frame(width: 120, height: 50)
              .overlay(Text("Error Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.semanticsErrorDefault), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Error Stroke").font(.caption))

            Rectangle()
              .fill(.themeColor(.semanticsErrorShade))
              .frame(width: 120, height: 50)
              .overlay(Text("Error Shade Fill").font(.caption).foregroundColor(.white))

            Rectangle()
              .stroke(.themeColor(.semanticsErrorShade), lineWidth: 4)
              .frame(width: 120, height: 50)
              .overlay(Text("Error Shade Stroke").font(.caption))
          }
        }
      }
      .padding()
    }
  }

#endif
