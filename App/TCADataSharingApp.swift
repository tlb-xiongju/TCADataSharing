//
//  TCADataSharingApp.swift
//  TCADataSharing
//
//  Created by 熊　炬 on 2025/08/01.
//

import ComposableArchitecture
import Dependencies
import SwiftUI

@main
struct TCADataSharingApp: App {
  static let store = Store(initialState: Introduce.State()) {
    Introduce()
      ._printChanges()
  }
  
  var body: some Scene {
    WindowGroup {
      IntroduceView(store: Self.store)
    }
  }
}
