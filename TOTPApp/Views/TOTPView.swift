//
//  TOTPView.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import Combine
import SwiftUI

struct TOTPView: View {
  // MARK: Lifecycle
  
  init(account: Account, timer: AnyPublisher<Date, Never>) {
    self.account = account
    let newTotp = totp(time: Date().timeIntervalSince1970, secret: account.secret)
    switch newTotp {
    case .success(let code):
      self.computedTotp = code
    case .failure:
      computedTotp = TOTP(password: 0, generatedAt: 0)
      self.errorOccured = .InvalidSecret
    }
    self.timer = timer
  }
  
  // MARK: Internal
  
  func updateTotp() {
    let newTotp = totp(time: Date().timeIntervalSince1970, secret: account.secret)
    switch newTotp {
    case .success(let code):
      self.computedTotp = code
    case .failure:
      computedTotp = TOTP(password: 0, generatedAt: 0)
      self.errorOccured = .InvalidSecret
    }
  }
  
  let account: Account
  let timer: AnyPublisher<Date, Never>
  @State var computedTotp: TOTP
  @State var errorOccured: TOTPError? = .none
  @State var text = ""
  @State var overlayText = ""
  
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 193/255, blue: 251/255), .blue]),
                             startPoint: .top, endPoint: .bottom))
        .shadow(radius: 0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      VStack {
        Text("\(account.displayName)")
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(.title2, design: .rounded).bold())
          .padding([.top, .leading, .trailing])
        Text("\(account.username)")
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.system(.subheadline, design: .rounded))
          .padding([.top], 0.5)
          .padding([.leading, .trailing])
        Text(verbatim: self.overlayText == "" ? text : overlayText)
          .onReceive(timer) { _ in
            updateTotp()
            if (self.computedTotp.password == 0) {
              self.text = "An error occurred."
            } else {
              // Don't ask
              self.text = String(String(String(self.computedTotp.password).reversed())
                .padding(toLength: 6,withPad: "0",startingAt: 0).reversed())
            }
          }
          .font(.system(.largeTitle, design: .rounded).bold())
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 2)
          .padding([.leading, .trailing, .bottom])
        
        ProgressView(value: Float(totpTimeRemaining(startTime: self.computedTotp.generatedAt, period: 30)), total: 30)
          .tint(Color(red: 1, green: 1, blue: 1))
          .padding([.leading, .trailing, .bottom])
      }
      .frame(maxWidth: .infinity)
    }
    .padding(10)
    .onTapGesture {
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(String(self.computedTotp.password), forType: .string)
      
      Task {
        self.overlayText = "Copied!"
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        self.overlayText = ""
      }
    }
  }
}

// #Preview {
//  TOTPView(account: Account(secret: "", username: "Hello", displayName: "World"))
//}
