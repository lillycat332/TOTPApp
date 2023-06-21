//
//  ContentView.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import LocalAuthentication
import SwiftData
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
  // MARK: Internal
  
  var body: some View {
    Group {
      if unlocked {
        ScrollView {
          VStack {
            ForEach(accounts, id: \.displayName) { account in
              TOTPView(account: account, timer: self.timer)
                .frame(maxWidth: .infinity)
                .contextMenu {
                  Button {
                    self.modelContext.delete(account)
                  } label: {
                    Text("Delete")
                  }
                }
            }
          }
        }
      } else {
        Text("Please use Touch ID to unlock.")
      }
    }.onAppear(perform: authenticate)
      .toolbar {
        ToolbarItemGroup {
          Spacer()
          Button(action: { modalOpen = !modalOpen }) {
            Image(systemName: "person.fill.badge.plus")
          }
          .tint(.blue)
          .popover(isPresented: $modalOpen, arrowEdge: .bottom) {
            ModalView(username: $username, displayName: $displayName, secret: $secret, modalOpen: $modalOpen)
          }
        }
      }.toolbarBackground(.ultraThinMaterial, for: .automatic)
  }
  
  func authenticate() {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
      let reason = "unlock your TOTP codes"
      
      context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
        if success {
          unlocked = true
        }
      }
    }
  }
  
  // MARK: Private
  
  @Environment(\.modelContext) private var modelContext
  @Query private var accounts: [Account]
  @State private var username: String = ""
  @State private var displayName: String = ""
  @State private var secret: String = ""
  @State private var modalOpen = false
  @State private var unlocked = false
  @State private var timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common)
    .autoconnect()
    .eraseToAnyPublisher()
}

// MARK: - ModalView

// struct ContentView: View {
//  @Environment(\.modelContext) var modelContext
//  @Query var accounts: [Account]
//  @State var username: String = ""
//  @State var displayName: String = ""
//  @State var secret: String = ""
//  @State var modalOpen = false
//  @State var unlocked = true
//
//  //    func authenticate() {
//  //      let context = LAContext()
//  //      var error: NSError?
//  //
//  //      if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
//  //        let reason = "unlock your TOTP codes"
//  //
//  //        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
//  //          if success {
//  //            unlocked = true
//  //          }
//  //        }
//  //      }
//  //    }
//
//  var body: some View {
//    NavigationView {
//      ScrollView {
//        VStack {
//          ForEach(accounts, id: \.displayName) { account in
//            TOTPView(account: account)
//              .frame(maxWidth: .infinity)
//          }
//        }
//      }
//      .toolbar() {
//        ToolbarItem(placement: .topBarTrailing) {
//          Button(action: {modalOpen = !modalOpen}) {
//            Image(systemName: "person.fill.badge.plus")
//          }
//          .popover(isPresented: $modalOpen) {
//            ModalView(username: $username, displayName: $displayName, secret: $secret, modalOpen: $modalOpen)
//          }
//        }
//      }
//    }
//  }
// }

struct ModalView: View {
  @Environment(\.modelContext) private var modelContext
  @Binding var username: String
  @Binding var displayName: String
  @Binding var secret: String
  @Binding var modalOpen: Bool
  var body: some View {
    VStack {
      Text("Add account")
      TextField("Username", text: $username)
      TextField("Display Name", text: $displayName)
      TextField("Secret", text: $secret)
      Button(action: {
        let acc = Account(secret: secret, username: username, displayName: displayName)
        modelContext.insert(acc)
        modalOpen = !modalOpen
      }) {
        Text("Add")
      }
    }
    .padding()
  }
}

#Preview {
  ContentView()
    .modelContainer(for: Account.self, inMemory: true)
}
