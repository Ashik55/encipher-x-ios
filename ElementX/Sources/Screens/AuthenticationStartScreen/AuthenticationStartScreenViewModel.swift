//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AuthenticationStartScreenViewModelType = StateStoreViewModel<AuthenticationStartScreenViewState, AuthenticationStartScreenViewAction>

class AuthenticationStartScreenViewModel: AuthenticationStartScreenViewModelType, AuthenticationStartScreenViewModelProtocol {
    
    //new vars
    let authenticationService: AuthenticationServiceProtocol
    let authenticationFlow: AuthenticationFlow
    let userIndicatorController: UserIndicatorControllerProtocol
    
    
    private var actionsSubject: PassthroughSubject<AuthenticationStartScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AuthenticationStartScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(webRegistrationEnabled: Bool,   authenticationService: AuthenticationServiceProtocol,
         authenticationFlow: AuthenticationFlow,
         userIndicatorController: UserIndicatorControllerProtocol
    ) {
        
        self.authenticationService = authenticationService
            self.authenticationFlow = authenticationFlow
            self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: AuthenticationStartScreenViewState(isWebRegistrationEnabled: webRegistrationEnabled,
                                                                        isQRCodeLoginEnabled: !ProcessInfo.processInfo.isiOSAppOnMac))
    }
    
    private func configureAndContinue() async {
           let homeserver = authenticationService.homeserver.value

           // If login mode is unknown, configure the authentication service.
           guard homeserver.loginMode == .unknown || authenticationService.flow != authenticationFlow else {
               actionsSubject.send(.loginManually)
               return
           }

           startLoading()
           defer { stopLoading() }

           switch await authenticationService.configure(for: homeserver.address, flow: authenticationFlow) {
           case .success:
               actionsSubject.send(.loginManually)
           case .failure(let error):
               handleAuthenticationError(error)
           }
       }
    
    private func handleAuthenticationError(_ error: AuthenticationServiceError) {
          switch error {
          case .invalidServer, .invalidHomeserverAddress:
              displayError(.homeserverNotFound)
          case .invalidWellKnown(let error):
              displayError(.invalidWellKnown(error))
          case .slidingSyncNotAvailable:
              displayError(.slidingSync)
          case .loginNotSupported:
              displayError(.login)
          case .registrationNotSupported:
              displayError(.registration)
          default:
              displayError(.unknownError)
          }
      }
    
    private func startLoading(label: String = L10n.commonLoading) {
           userIndicatorController.submitIndicator(UserIndicator(type: .modal, title: label, persistent: true))
       }

       private func stopLoading() {
           userIndicatorController.retractAllIndicators()
       }

       private func displayError(_ type: ServerConfirmationScreenAlert) {
           
           print("Error \(type)")
//           switch type {
//           case .homeserverNotFound:
//               state.bindings.alertInfo = AlertInfo(
//                   id: .homeserverNotFound,
//                   title: L10n.errorUnknown,
//                   message: L10n.screenChangeServerErrorInvalidHomeserver
//               )
//           case .invalidWellKnown(let error):
//               state.bindings.alertInfo = AlertInfo(
//                   id: .invalidWellKnown(error),
//                   title: L10n.commonServerNotSupported,
//                   message: L10n.screenChangeServerErrorInvalidWellKnown(error)
//               )
//           case .slidingSync:
//               state.bindings.alertInfo = AlertInfo(
//                   id: .slidingSync,
//                   title: L10n.commonServerNotSupported,
//                   message: L10n.screenChangeServerErrorNoSlidingSyncMessage,
//                   primaryButton: .init(title: L10n.actionLearnMore, role: .cancel) {
//                       UIApplication.shared.open(self.userIndicatorController.slidingSyncLearnMoreURL)
//                   },
//                   secondaryButton: .init(title: L10n.actionCancel, action: nil)
//               )
//           case .login:
//               state.bindings.alertInfo = AlertInfo(
//                   id: .login,
//                   title: L10n.commonServerNotSupported,
//                   message: L10n.screenLoginErrorUnsupportedAuthentication
//               )
//           case .registration:
//               state.bindings.alertInfo = AlertInfo(
//                   id: .registration,
//                   title: L10n.commonServerNotSupported,
//                   message: L10n.errorAccountCreationNotPossible
//               )
//           case .unknownError:
//               state.bindings.alertInfo = AlertInfo(id: .unknownError)
//           }
       }

    override func process(viewAction: AuthenticationStartScreenViewAction) {
        switch viewAction {
        case .loginManually:
//            actionsSubject.send(.loginManually)
            Task { await configureAndContinue() }
        case .loginWithQR:
            actionsSubject.send(.loginWithQR)
        case .register:
            actionsSubject.send(.register)
        case .reportProblem:
            actionsSubject.send(.reportProblem)
        }
    }
}
