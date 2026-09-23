//
//  Text+ThemeTextStyle.swift
//  RecipeTest
//
//  Created by Danjan ( https://github.com/Dannjann )
//  Copyright © 2023 Danjan. All rights reserved.
//

import Foundation
import SwiftUI

/// replicate SwiftUI `font(_ font: Font?) -> Text`
extension Text {
  func themeTextStyle(_ textStyle: Font.ThemeTextStyle) -> Text {
    font(.themeTextStyle(textStyle))
  }
}

#if DEBUG

  struct Text_Previews: PreviewProvider {
    static var previews: some View {
      Form {
        Section {
          Group {
            Text("LargeTitle")
              .themeTextStyle(.largeTitle)

            Text("Title1")
              .themeTextStyle(.title1)

            Text("Title2")
              .themeTextStyle(.title2)

            Text("Title3")
              .themeTextStyle(.title3)

            Text("Title3Regular")
              .themeTextStyle(.title3Regular)
          }
        }

        Section {
          Group {
            Text("BodyBold")
              .themeTextStyle(.bodyBold)

            Text("BodySemibold")
              .themeTextStyle(.bodySemibold)

            Text("BodyRegular")
              .themeTextStyle(.bodyRegular)

            Text("SubHeadlineSemibold")
              .themeTextStyle(.subheadlineSemibold)

            Text("SubHeadlineRegular")
              .themeTextStyle(.subheadlineRegular)

            Text("FootnoteBold")
              .themeTextStyle(.footnoteBold)

            Text("FootnoteRegular")
              .themeTextStyle(.footnoteRegular)

            Text("CaptionBold")
              .themeTextStyle(.captionBold)

            Text("CaptionRegular")
              .themeTextStyle(.captionRegular)

            Text("NavigationLabel")
              .themeTextStyle(.navigationLabel)
          }
        }
      }
    }
  }

#endif
