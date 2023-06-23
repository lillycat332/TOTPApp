//
//  TOTPLib.swift
//  TOTPApp
//
//  Created by Lilly Cham on 20/06/2023.
//

import Foundation
import CryptoKit
import Base32

/// A TOTP password.
struct TOTP {
  let password: Int
  let generatedAt: TimeInterval
}

extension TOTP: CustomStringConvertible {
  var description: String {
    "TOTP: Password \(self.password), generated at \(self.generatedAt)"
  }
}

private func generateHMAC(for data: Data, with keydata: Data) -> Data {
  let key = SymmetricKey(data: keydata)
  let code = HMAC<Insecure.SHA1>.authenticationCode(for: data, using: key)
  
  return Data(code)
}

/// Represents errors that can occur during the generation of TOTP codes.
enum TOTPError: Error {
  case InvalidSecret
}

/// Given a unix timestamp and a TOTP secret, return a 6-digit TOTP code.
func totp(time: TimeInterval, secret: String, period: Double = 30.0) -> Result<TOTP, TOTPError> {
  var now = UInt64(time / period).bigEndian
  
  // Return err if base32decode fails - the secret is probably not valid
  guard let key = base32Decode(secret) else {
    return .failure(.InvalidSecret)
  }
  
  // Convert the timer to raw data to be used in the HMAC algorithm
  let counter = withUnsafeBytes(of: &now) {
    Data($0)
  }
  
  let hash = generateHMAC(for: counter, with: Data(key))
  
  // Weird hack
  let shortHash = UInt32(bigEndian: hash.withUnsafeBytes { ptr -> UInt32 in
    let offset = ptr[hash.count - 1] & 0x0F
    // if we fail to obtain the addr of the pointer something is seriously fucked.
    let truncatedHashPtr = ptr.baseAddress! + Int(offset)
    return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
  })
  
  return .success(TOTP(password: Int((shortHash & 0x7FFFFFFF) % 1000000), generatedAt: time))
}

func totpTimeRemaining(startTime: TimeInterval, period: Double) -> Int {
  let calendar = Calendar.current
  let date = Date()
  
  let seconds = calendar.component(.second, from: date)
  
  return if seconds < 30 {
    30 - seconds
  } else {
    30 - (seconds - 30)
  }
}
