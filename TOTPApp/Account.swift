//
//  Account.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import Foundation
import SwiftData

@Model
class Account {
  init(secret: String, username: String, displayName: String) {
    self.secret = secret
    self.username = username
    self.displayName = displayName
  }
  
  @Attribute(.unique) var secret: String
  var username: String
  var displayName: String
}
