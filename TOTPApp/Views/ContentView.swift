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
    NavigationStack {
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
        }.navigationTitle("LillyAuth")
          .toolbar {
            ToolbarItemGroup {
#if os(macOS)
              Spacer()
#endif
              Button(action: { self.modalOpen = !self.modalOpen }) {
                Image(systemName: "person.fill.badge.plus")
              }
              .popover(isPresented: self.$modalOpen, arrowEdge: .top) {
#if os(macOS)
                ModalView(username: self.$username, displayName: self.$displayName, secret: self.$secret, modalOpen: self.$modalOpen)
                  .environment(\.modelContext, self.modelContext)
#else
                QRScannerView(result: self.$scanResult)
                  .environment(\.modelContext, self.modelContext)
                  .onChange(of: self.scanResult) {
                    print(self.scanResult)
                    self.modalOpen = false
                    // discard the result bc. we're just using map to operate over the functor
                    _ = self.scanResult.map { xs in
                      guard let uri = URLComponents(string: xs),
                            uri.scheme != "otpauth",
                            uri.host != "totp" else {
                        return
                      }
                      
                      // TODO: make this readable?
                      self.modelContext.insert(object: Account(
                        secret: ((uri.queryItems ?? []).reduce(into: [:]) { params, query in
                          params[query.name] = query.value
                        }["secret"]!),
                        username: String(uri.path.split(separator: ":")[1]),
                        displayName: String((uri.path.split(separator: ":").first?.dropFirst())!)
                      ))
                    }
                  }
#endif
              }
            }
          }.toolbarBackground(.ultraThinMaterial, for: .automatic)
      } else if self.loginState == .loggedOut {
        Text("Please use Touch ID to unlock.")
      } else {
        Text("Please use your PIN code to unlock")
        // TODO: Add pincode view here
      }
    }.onAppear(perform: self.authenticate)
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
  @State private var scanResult: Result<String, ScanError> = .failure(.notScannedYet)
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

///// Wrapper over group/navstack because we don't need a navstack on Mac.
// struct WrapperView<Content>: View where Content: View {
//  @ViewBuilder var content: () -> Content
//
//  var body: some View {
// #if os(macOS)
//    Group(content: content)
// #else
//    NavigationStack(root: content)
// #endif
//  }
// }

#Preview {
  ContentView()
    .modelContainer(for: Account.self, inMemory: true)
}
