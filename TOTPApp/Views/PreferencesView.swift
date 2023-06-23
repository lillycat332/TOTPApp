//
//  PreferencesView.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import SwiftData
import SwiftUI

// MARK: - PreferencesView

struct PreferencesView: View {
  var body: some View {
    TabView {
      AccountSettingsView()
        .tabItem {
          Label("Accounts", systemImage: "person")
        }
      SecuritySettingsView()
        .tabItem {
          Label("Security", systemImage: "lock")
        }
    }
    .frame(width: 450, height: 250)
    .padding()
  }
}

// MARK: - AccountSettingsView

struct AccountSettingsView: View {
  // MARK: Internal
  
  var body: some View {
    VStack {
      Button {
        let items = try? self.context.fetch(FetchDescriptor(predicate: #Predicate<Account> { _ in
          true
        }))
        items.map { accounts in
          accounts.forEach { account in self.context.delete(account) }
        }
      } label: {
        Text("Delete Everything")
      }
    }
  }
  
  // MARK: Private
  @Environment(\.modelContext) private var context
}

// MARK: - SecuritySettingsView

struct SecuritySettingsView: View {
  // MARK: Internal
  
  var body: some View {
    VStack {
      Toggle("Use Biometrics", isOn: $biometricsEnabled)
    }
  }
  
  // MARK: Private
  @AppStorage("biometricsEnabled") private var biometricsEnabled = false
}

#Preview {
  PreferencesView()
}
