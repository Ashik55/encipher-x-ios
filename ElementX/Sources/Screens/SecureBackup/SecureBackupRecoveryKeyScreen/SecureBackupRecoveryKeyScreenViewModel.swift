//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecureBackupRecoveryKeyScreenViewModelType = StateStoreViewModel<SecureBackupRecoveryKeyScreenViewState, SecureBackupRecoveryKeyScreenViewAction>

class SecureBackupRecoveryKeyScreenViewModel: SecureBackupRecoveryKeyScreenViewModelType, SecureBackupRecoveryKeyScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    let userID: String
 
    
    private var actionsSubject: PassthroughSubject<SecureBackupRecoveryKeyScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupRecoveryKeyScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         isModallyPresented: Bool, userID: String) {
        self.secureBackupController = secureBackupController
        self.userIndicatorController = userIndicatorController
        self.userID = userID
     
        
        super.init(initialViewState: .init(isModallyPresented: isModallyPresented,
                                           mode: secureBackupController.recoveryState.value.viewMode,
                                           bindings: .init()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecureBackupRecoveryKeyScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .generateKey:
            state.isGeneratingKey = true
            
            Task {
                switch await secureBackupController.generateRecoveryKey() {
                case .success(let key):
                    state.recoveryKey = key
                case .failure(let error):
                    MXLog.error("Failed generating recovery key with error: \(error)")
                    state.bindings.alertInfo = .init(id: .init())
                }
                
                state.isGeneratingKey = false
            }
        case .copyKey:
            UIPasteboard.general.string = state.recoveryKey
            userIndicatorController.submitIndicator(.init(title: "Copied recovery key"))
            state.doneButtonEnabled = true
        case .keySaved:
            state.doneButtonEnabled = true
        case .confirmKey:
            Task {
                showLoadingIndicator()
                
                let getPasskeyResponse = try await getPaaskey(userId: userID, password: state.bindings.password)
                
                print("getPasskeyResponse ==>: \(getPasskeyResponse)")
                
                let decryptedRecoveryKey = try PasskeyEncryption.decrypt(encryptedPasskey: getPasskeyResponse.passkey, passphrase: state.bindings.password)
                
                print("decryptedRecoveryKey ==>: \(decryptedRecoveryKey)")
                
                switch await secureBackupController.confirmRecoveryKey(decryptedRecoveryKey) {
                case .success:
                    actionsSubject.send(.done(mode: context.viewState.mode))
                case .failure(let error):
                    MXLog.error("Failed confirming recovery key with error: \(error)")
                    state.bindings.alertInfo = .init(id: .init(),
                                                     title: L10n.screenRecoveryKeyConfirmErrorTitle,
                                                     message: L10n.screenRecoveryKeyConfirmErrorContent)
                }
                
                hideLoadingIndicator()
            }
        case .cancel:
            actionsSubject.send(.cancel)
        case .done:
            
            Task {
                  do {
//                      print("userId  ==>>\(userID)")
////                      print("Server RecoveryKey  ==>>\(state.bindings.confirmationRecoveryKey)")
//                      print("Server RecoveryKey  ==>>\(String(describing: state.recoveryKey))")
//                      print("password  ==>>\(state.bindings.password)")
                      
                      let passkeyResponse = try await savePasskey(userId: userID, recoveryKey: state.recoveryKey, password: state.bindings.password)
//                      print("passkeyResponse ==>: \(passkeyResponse)")
                      
                      if(passkeyResponse.encryptedPasskey != nil){
                          state.bindings.alertInfo =
                              .init(id: .init(),
                            title: "Recovery Key Saved",
                            message: "You Recovery key succesfylly saved in Encipher's Secure Vault, remember the password to decrypt your data next time",
                            primaryButton: .init(title: L10n.actionContinue) {
                                  [weak self] in
                                  guard let self else { return }
                                  actionsSubject.send(.done(mode: context.viewState.mode))
                                  
                              },
                            secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
                            
                      }
                      // If you need to perform actions after the async operation
//                      actionsSubject.send(.done(mode: context.viewState.mode))
                  } catch {
                      MXLog.error("Failed saving passkey with error: \(error)")
                      state.bindings.alertInfo = .init(id: .init(),
                                                      title: "Passkey Error",
                                                      message: "Failed to save recovery key: \(error.localizedDescription)")
                  }
              }
            
     
            
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(SecureBackupRecoveryKeyScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}



func savePasskey( userId: String, recoveryKey: String?, password: String) async throws -> CreatePasskeyResponse {
    guard let recoveryKey = recoveryKey else {
        throw APIError.custom(message: "Recovery key is missing")
    }
    
    print("plain recoveryKey==>>\(recoveryKey)")
    
    let encryptedPassKey = try PasskeyEncryption.encrypt(passkey: recoveryKey, passphrase: password)
    
    print("encryptedPassKey==>>\(encryptedPassKey)")
    
    let body: [String: String] = [
        "passkey": encryptedPassKey,
        "passphrase": password
    ]
    
   
    print("savePasskey body  ==>>\(body)")

    return try await APIClient.request(
        path: "auth/passkey/\(userId)",
        method: .POST,
        body: body
    )
}


func getPaaskey(userId: String, password: String?) async throws -> GetPasskeyResponse {
    guard let password = password else {
        throw APIError.custom(message: "Password is required")
    }

    print("getPaaskey called  ==>>\(password)")
    return try await APIClient.request(
        path: "auth/passkey/\(userId)?passphrase=\(password)"
    )
}

extension SecureBackupRecoveryState {
    var viewMode: SecureBackupRecoveryKeyScreenViewMode {
        switch self {
        case .disabled:
            return .setupRecovery
        case .enabled:
            return .changeRecovery
        case .incomplete:
            return .fixRecovery
        default:
            return .unknown
        }
    }
}
