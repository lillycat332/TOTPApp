//
//  PreferencesView.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import SwiftUI
import SwiftData

struct AccountSettingsView: View {
  @Environment(\.modelContext) private var context
  @State private var username: String = ""
  @State private var displayName: String = ""
  @State private var secret: String = ""
  
  var body: some View {
    VStack {
//      Text("Add account")
//      TextField("Username", text: $username)
//      TextField("Display Name", text: $displayName)
//      TextField("Secret", text: $secret)
//      Button(action: {
//        let acc = Account(secret: secret, username: username, displayName: displayName)
//        context.insert(acc)
//      }, label: {Text("Add")})
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
}

struct PreferencesView: View {
  var body: some View {
    TabView {
      AccountSettingsView()
        .tabItem {
          Label("Accounts", systemImage: "person.fill")
        }
    }
    .frame(width: 450, height: 250)
    .padding()
  }
}

#Preview {
  PreferencesView()
}
