//
//  TOTPApp.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import SwiftUI
import SwiftData

@main
struct TOTPApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
#if os(macOS)
        .onAppear {
          Task {
            NSApplication.shared.windows.forEach { window in
              window.standardWindowButton(.zoomButton)?.isEnabled = false
            }
          }
        }
        .frame(minWidth: 200, maxWidth: 300, minHeight: 500)
#endif
    }
    .modelContainer(for: Account.self)
#if os(macOS)
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unifiedCompact(showsTitle: false))
    .windowResizability(.contentSize)
#endif
#if os(macOS)
    Settings {
      PreferencesView()
        .modelContainer(for: Account.self)
    }
#endif
  }
}

