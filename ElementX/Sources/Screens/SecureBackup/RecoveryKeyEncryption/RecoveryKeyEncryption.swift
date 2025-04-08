//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//


import Foundation
import CommonCrypto

class PasskeyEncryption {
    // MARK: - Constants
    private static let algorithm = kCCAlgorithmAES
    private static let keyLength = kCCKeySizeAES256 // 256 bits = 32 bytes
    private static let iterationCount = 65536
    private static let ivLength = kCCBlockSizeAES128 // 16 bytes
    
    // MARK: - Encryption
    
    /**
     * Encrypts a passkey using the passphrase.
     * @param passkey The passkey to encrypt
     * @param passphrase The passphrase to use
     * @return The encrypted passkey as a Base64 encoded string
     */
    static func encrypt(passkey: String, passphrase: String) throws -> String {
        // Generate a random IV
        let iv = generateRandomBytes(length: ivLength)
        
        // Generate key from passphrase using IV as salt (matching Kotlin implementation)
        guard let key = deriveKey(passphrase: passphrase, salt: iv) else {
            throw CryptoError.keyDerivationError
        }
        
        // Encrypt the passkey
        guard let passkeyData = passkey.data(using: .utf8) else {
            throw CryptoError.invalidInput
        }
        
        var bufferSize = passkeyData.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted = 0
        
        let status = passkeyData.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyLength,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, passkeyData.count,
                        &buffer, bufferSize,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw CryptoError.encryptionError
        }
        
        let encryptedData = Data(bytes: buffer, count: numBytesEncrypted)
        
        // Combine IV and encrypted data
        var combinedData = Data()
        combinedData.append(iv)
        combinedData.append(encryptedData)
        
        // Return Base64 encoded string
        return combinedData.base64EncodedString()
    }
    
    // MARK: - Decryption
    
    /**
     * Decrypts an encrypted passkey using the passphrase.
     * @param encryptedPasskey The encrypted passkey as a Base64 encoded string
     * @param passphrase The passphrase to use
     * @return The decrypted passkey
     */
    static func decrypt(encryptedPasskey: String, passphrase: String) throws -> String {
        // Decode Base64 string
        guard let combinedData = Data(base64Encoded: encryptedPasskey) else {
            throw CryptoError.invalidInput
        }
        
        guard combinedData.count > ivLength else {
            throw CryptoError.invalidInput
        }
        
        // Extract IV and encrypted data
        let iv = combinedData.subdata(in: 0..<ivLength)
        let encryptedData = combinedData.subdata(in: ivLength..<combinedData.count)
        
        // Generate key from passphrase using IV as salt (matching Kotlin implementation)
        guard let key = deriveKey(passphrase: passphrase, salt: iv) else {
            throw CryptoError.keyDerivationError
        }
        
        // Decrypt the data
        var bufferSize = encryptedData.count + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesDecrypted = 0
        
        let status = encryptedData.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                iv.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyLength,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, encryptedData.count,
                        &buffer, bufferSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw CryptoError.decryptionError
        }
        
        let decryptedData = Data(bytes: buffer, count: numBytesDecrypted)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionError
        }
        
        return decryptedString
    }
    
    // MARK: - Helper Methods
    
    private static func generateRandomBytes(length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        return data
    }
    
    private static func deriveKey(passphrase: String, salt: Data) -> Data? {
        guard let passphraseData = passphrase.data(using: .utf8) else {
            return nil
        }
        
        var derivedKey = Data(count: keyLength)
        
        let result = derivedKey.withUnsafeMutableBytes { keyBytes in
            passphraseData.withUnsafeBytes { passphraseBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passphraseBytes.baseAddress, passphraseData.count,
                        saltBytes.baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterationCount),
                        keyBytes.baseAddress, keyLength
                    )
                }
            }
        }
        
        return result == kCCSuccess ? derivedKey : nil
    }
    
    // MARK: - Error Types
    enum CryptoError: Error {
        case keyDerivationError
        case encryptionError
        case decryptionError
        case invalidInput
    }
}
