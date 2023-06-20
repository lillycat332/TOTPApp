//
//  TOTPAppApp.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import SwiftUI
import SwiftData

@main
struct TOTPAppApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
