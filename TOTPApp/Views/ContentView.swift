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

  @State var loginState: LoginState = .loggedOut

  var body: some View {
    Group {
      if !self.biometricsEnabled || self.loginState == .loggedIn {
        ScrollView {
          VStack {
            ForEach(self.accounts, id: \.displayName) { account in
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
      } else if self.loginState == .loggedOut {
        Text("Please use Touch ID to unlock.")
      } else {
        Text("Please use your PIN code to unlock")
        // TODO: Add pincode view here
      }
    }.onAppear(perform: self.authenticate)
      .toolbar {
        ToolbarItemGroup {
          Spacer()
          Button(action: { self.modalOpen = !self.modalOpen }) {
            Image(systemName: "person.fill.badge.plus")
          }
          .tint(.blue)
          .popover(isPresented: self.$modalOpen, arrowEdge: .bottom) {
            ModalView(username: self.$username, displayName: self.$displayName, secret: self.$secret, modalOpen: self.$modalOpen)
              .environment(\.modelContext, self.modelContext)
          }
        }
      }.toolbarBackground(.ultraThinMaterial, for: .automatic)
  }

  func authenticate() {
    // Early return if biometric login isn't enabled
    guard self.biometricsEnabled else { return }

    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      print(error?.localizedDescription ?? "Can't evaluate policy")
      // fallback to passcode.
      self.loginState = .fallbackToPassword

      return
    }

    Task {
      do {
        try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock your 2FA codes")
        self.loginState = .loggedIn
      } catch {
        print(error.localizedDescription)
        // Fall back to a asking for username and password.
        self.loginState = .fallbackToPassword

        // TODO: Add fallback?
        return
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
  @AppStorage("biometricsEnabled") private var biometricsEnabled = false
  @State private var timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common)
    .autoconnect()
    .eraseToAnyPublisher()
}

// MARK: - ModalView

struct ModalView: View {
  @Environment(\.modelContext) private var modelContext
  @Binding var username: String
  @Binding var displayName: String
  @Binding var secret: String
  @Binding var modalOpen: Bool
  var body: some View {
    VStack {
      Text("Add account")
      TextField("Username", text: self.$username)
      TextField("Display Name", text: self.$displayName)
      TextField("Secret", text: self.$secret)
      Button(action: {
        let acc = Account(secret: secret, username: username, displayName: displayName)
        self.modelContext.insert(acc)
        self.modalOpen = !self.modalOpen
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
