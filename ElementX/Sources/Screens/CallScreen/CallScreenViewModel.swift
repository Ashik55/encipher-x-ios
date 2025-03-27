//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import CallKit
import Combine
import SwiftUI
import Foundation


typealias CallScreenViewModelType = StateStoreViewModel<CallScreenViewState, CallScreenViewAction>

class CallScreenViewModel: CallScreenViewModelType, CallScreenViewModelProtocol {
    private let elementCallService: ElementCallServiceProtocol
    private let configuration: ElementCallConfiguration
    private let isPictureInPictureAllowed: Bool
    
    private let widgetDriver: ElementCallWidgetDriverProtocol
    
    var audioCall: Bool? = nil  // Changed from `let` to `var`
    
    private let actionsSubject: PassthroughSubject<CallScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CallScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// Designated initialiser
    /// - Parameters:
    ///   - elementCallService: service responsible for setting up CallKit
    ///   - roomProxy: The room in which the call should be created
    ///   - callBaseURL: Which Element Call instance should be used
    ///   - clientID: Something to identify the current client on the Element Call side
    
    init(elementCallService: ElementCallServiceProtocol,
         configuration: ElementCallConfiguration,
         allowPictureInPicture: Bool,
         appHooks: AppHooks) {
        
        self.elementCallService = elementCallService
        self.configuration = configuration
        isPictureInPictureAllowed = allowPictureInPicture
        
        switch configuration.kind {
        case .genericCallLink(let url):
            widgetDriver = GenericCallLinkWidgetDriver(url: url)
            
            
        case .roomCall(let roomProxy, let clientProxy, _, _, _, _, _,let isAudioCall):
            
            
            print("roomCall==>>\(isAudioCall)")
            audioCall = isAudioCall
            guard let deviceID = clientProxy.deviceID else { fatalError("Missing device ID for the call.") }
            widgetDriver = roomProxy.elementCallWidgetDriver(deviceID: deviceID)
            
            
        }
        
        super.init(initialViewState: CallScreenViewState(messageHandler: Self.eventHandlerName,
                                                         script: Self.eventHandlerInjectionScript,
                                                         certificateValidator: appHooks.certificateValidatorHook))
        
        state.bindings.javaScriptMessageHandler = { [weak self] message in
            guard let self, let message = message as? String else { return }
            Task { await self.widgetDriver.handleMessage(message) }
        }
        
        elementCallService.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case let .setAudioEnabled(enabled, roomID):
                    guard roomID == configuration.callRoomID else {
                        MXLog.error("Received mute request for a different room: \(roomID) != \(configuration.callRoomID)")
                        return
                    }
//                    print(" elementCallService.actions audio==>\(enabled)")
                    Task {
                        await self.setAudioEnabled(enabled)
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        widgetDriver.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] receivedMessage in
                guard let self else { return }
                
                
//                print("widgetDriver.messagePublisher==>\(receivedMessage)")
                
                Task {
                    await self.postJSONToWidget(receivedMessage)
                }
            }
            .store(in: &cancellables)
        
        widgetDriver.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .callEnded:
                    actionsSubject.send(.dismiss)
                case .mediaStateChanged(let audioEnabled, let videoEnabled):
                    print("mediaStateChanged Triggered==>\(audioEnabled) \(videoEnabled)")
                    elementCallService.setAudioEnabled(audioEnabled, roomID: configuration.callRoomID)
                }
            }
            .store(in: &cancellables)
        
        setupCall()
    }
    
    override func process(viewAction: CallScreenViewAction) {
        switch viewAction {
        case .urlChanged(let url):
            guard let url else { return }
            print("URL changed to==>>>> \(url)")
        case .pictureInPictureIsAvailable(let controller):
            MXLog.info("pictureInPictureIsAvailable==>")
            actionsSubject.send(.pictureInPictureIsAvailable(controller))
        case .navigateBack:
            Task { await handleBackwardsNavigation() }
        case .pictureInPictureWillStop:
            actionsSubject.send(.pictureInPictureStopped)
        case .endCall:
            actionsSubject.send(.dismiss)
        }
    }
    
    func stop() {
        Task {
            await hangup()
        }
        
        elementCallService.tearDownCallSession()
    }
    
    func extractRoomIDAndDisplayName(from url: URL) -> (roomId: String?, displayName: String?) {
        var urlString = url.absoluteString
        // Extract fragment if it exists
        if let fragmentIndex = urlString.firstIndex(of: "#") {
            urlString = String(urlString[fragmentIndex...]).dropFirst().description
        }

        guard let components = URLComponents(string: "https://dummy.com?\(urlString)"),
              let queryItems = components.queryItems else {
            return (nil, nil)
        }

        let roomId = queryItems.first(where: { $0.name == "roomId" })?.value
        let displayName = queryItems.first(where: { $0.name == "displayName" })?.value

        return (roomId, displayName)
    }
    func extractRoomDetails(from url: URL) -> (roomId: String?, displayName: String?, userId: String?) {
        var urlString = url.absoluteString
        // Extract fragment if it exists
        if let fragmentIndex = urlString.firstIndex(of: "#") {
            urlString = String(urlString[fragmentIndex...]).dropFirst().description
        }

        guard let components = URLComponents(string: "https://dummy.com?\(urlString)"),
              let queryItems = components.queryItems else {
            return (nil, nil, nil)
        }

        let roomId = queryItems.first(where: { $0.name == "roomId" })?.value
        let displayName = queryItems.first(where: { $0.name == "displayName" })?.value
        let userId = queryItems.first(where: { $0.name == "?userId" })?.value

        return (roomId, displayName, userId)
    }
  
   
    func extractURLParameters(from url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let fragment = components.fragment else {
            return [:]
        }
        
        let queryItems = fragment.split(separator: "&")
        var parameters: [String: String] = [:]
        
        for item in queryItems {
            let pair = item.split(separator: "=", maxSplits: 1).map { String($0) }
            if pair.count == 2, let decodedValue = pair[1].removingPercentEncoding {
                parameters[pair[0]] = decodedValue
            }
        }
        
        return parameters
    }
    
    func extractRoomID(from url: URL) -> String? {
        var urlString = url.absoluteString
        // Extract fragment if it exists
        if let fragmentIndex = urlString.firstIndex(of: "#") {
            urlString = String(urlString[fragmentIndex...]).dropFirst().description
        }

        guard let components = URLComponents(string: "https://dummy.com?\(urlString)"),
              let queryItems = components.queryItems else {
            return nil
        }

        return queryItems.first(where: { $0.name == "roomId" })?.value
    }
    
//    
//    func createCall(roomId: String?, userId: String?, isAudioCall: Bool) {
//        // Ensure we have a valid userId
//        guard let userId = userId else {
//            print("Error: User ID is missing")
//            return
//        }
//        // Construct the base URL
//        let baseURL = "https://dev.enciph-er.com/_matrix/client/v3/call/\(userId)"
//        
//        // Prepare the URL
//        guard let url = URL(string: baseURL) else {
//            print("Error: Invalid URL")
//            return
//        }
//        // Prepare the request body
//        let requestBody: [String: Any] = [
//            "room_id": roomId ?? "",
//            "call_type": isAudioCall ? "audio" : "video"
//        ]
//        
//        print("Create Call RequestBody ==>> \(requestBody)")
//        // Convert the body to JSON data
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
//            print("Error: Failed to serialize request body")
//            return
//        }
//        // Create the URLRequest
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Optional: Add authentication headers if required
//        // request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")
//        request.httpBody = jsonData
//        // Create URLSession data task
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            // Check for errors
//            if let error = error {
//                print("Network Error: \(error.localizedDescription)")
//                return
//            }
//            // Check HTTP response
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("Invalid response")
//                return
//            }
//            // Check response status code
//            print("Response Status Code: \(httpResponse.statusCode)")
//            // Process the response data
//            if let data = data {
//                do {
//                    // Try to parse the response as JSON
//                    if let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                        print("Create Call Response JSON==>: \(jsonResult)")
//                    }
//                } catch {
//                    print("Error parsing response JSON: \(error)")
//                }
//            }
//        }
//        
//        // Start the network request
//        task.resume()
//    }
//
//    func getCallDetails(userId: String?, roomId: String?, completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        // Construct the full URL
//        guard let url = URL(string: "https://dev.enciph-er.com/_matrix/client/v3/call/\(userId)?room_id=\(roomId)") else {
//            completion(.failure(NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//        
//        // Create the URLRequest
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        
//        // Optional: Add authentication headers if needed
//        // request.setValue("Bearer YOUR_TOKEN", forHTTPHeaderField: "Authorization")
//        
//        // Create URLSession data task
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            // Check for network errors
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            // Verify HTTP response
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.failure(NSError(domain: "ResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
//                return
//            }
//            
//            // Check response status code
//            guard (200...299).contains(httpResponse.statusCode) else {
//                completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode) error"])))
//                return
//            }
//            
//            // Process the response data
//            guard let data = data else {
//                completion(.failure(NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
//                return
//            }
//            
//            do {
//                // Parse JSON response
//                guard let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
//                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])))
//                    return
//                }
//                
//                // Successfully parsed, return the result
//                completion(.success(jsonResult))
//            } catch {
//                // JSON parsing error
//                completion(.failure(error))
//            }
//        }
//        
//        // Start the network request
//        task.resume()
//    }


    
//    async - await


    // Create Call Function (Async/Await)
    func createCall(roomId: String?, userId: String?, isAudioCall: Bool) async throws -> [String: Any] {
        guard let userId = userId else {
            throw NSError(domain: "UserError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])
        }

        let baseURL = "https://dev.enciph-er.com/_matrix/client/v3/call/\(userId)"
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let requestBody: [String: Any] = [
            "room_id": roomId ?? "",
            "call_type": isAudioCall ? "audio" : "video"
        ]

        print("Create Call RequestBody ==>> \(requestBody)")

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }

        let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        print("Create Call Response JSON==>: \(jsonResult)")
        
        return jsonResult
    }

    // Get Call Details Function (Async/Await)
    func getCallDetails(userId: String?, roomId: String?) async throws -> [String: Any] {
        guard let userId = userId, let roomId = roomId,
              let url = URL(string: "https://dev.enciph-er.com/_matrix/client/v3/call/\(userId)?room_id=\(roomId)") else {
            throw NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        
        print("RoomID==>\(roomId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
        }

        let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        print("Get Call Details Response JSON ==>: \(jsonResult)")
        
        return jsonResult
    }
   
    // MARK: - Private
    
    private func setupCall() {
        
//        print("setupCall Running==>")
        switch configuration.kind {
        case .genericCallLink(let url):
            state.url = url
            // We need widget messaging to work before enabling CallKit, otherwise mute, hangup etc do nothing.
            
        case .roomCall(let roomProxy, let clientProxy, let clientID, let elementCallBaseURL, let elementCallBaseURLOverride, let colorScheme, let notifyOtherParticipants, let audioCall):
            Task { [weak self] in
                guard let self else { return }
                
                let baseURL = if let elementCallBaseURLOverride {
                    elementCallBaseURLOverride
                } else if case .success(let wellKnown) = await clientProxy.getElementWellKnown(), let wellKnownCall = wellKnown?.call {
                    wellKnownCall.widgetURL
                } else {
                    elementCallBaseURL
                }
                
                switch await widgetDriver.start(baseURL: baseURL, clientID: clientID, colorScheme: colorScheme) {
                case .success(let url):
                    print("Call URL ==>> \(url)")
                    let (roomId, displayName, userId) = extractRoomDetails(from: url)
                    
                    do {
                        let callDetails = try await getCallDetails(userId: userId, roomId: roomId)

                        if let calls = callDetails["calls"] as? [[String: Any]], let firstCall = calls.first {
                            let callType = firstCall["call_type"] as? String ?? "N/A"
                   

                            print("Call Type: \(callType)")
                     

                            // Update state on the main thread **after API completion**
                            DispatchQueue.main.async {
                                self.state.roomId = roomId
                                self.state.displayName = displayName
                                self.state.isAudioCall = (callType == "audio")
                                self.state.url = url
                       
                            }
                        } else {
                            print("No Calls Found, Creating New Call...")

                            // Call createCall only when no call details exist
                            let newCallResponse = try await createCall(roomId: roomId, userId: userId, isAudioCall: audioCall ?? false)
                            print("New Call Created: \(newCallResponse)")

                            DispatchQueue.main.async {
                                self.state.roomId = roomId
                                self.state.displayName = displayName
                                self.state.isAudioCall = audioCall ?? false
                                self.state.url = url
                            }
                        }
                    } catch {
                        print("Error fetching call details, creating new call: \(error.localizedDescription)")

                        do {
                            let newCallResponse = try await createCall(roomId: roomId, userId: userId, isAudioCall: audioCall ?? false)
                            print("New Call Created: \(newCallResponse)")

                            DispatchQueue.main.async {
                                self.state.roomId = roomId
                                self.state.displayName = displayName
                                self.state.isAudioCall = audioCall ?? false
                                self.state.url = url
                       
                            }
                        } catch {
                            print("Error creating call: \(error.localizedDescription)")
                        }
                    }
                    
                    
                    
                    
                    
                    
                    
////                    print("Room ID: \(roomId ?? "N/A")")
////                    print("Display Name: \(displayName ?? "N/A")")
////                    print("User ID: \(userId ?? "N/A")")
////                    print("AudioCall: \(audioCall)")
//
//                    getCallDetails(userId: userId, roomId: roomId) { [weak self] result in
//                        guard let self = self else { return }
//                        
//                        // Prepare state update values outside of the closure
//                          let stateUrl = url
//                          let stateRoomId = roomId
//                          let stateDisplayName = displayName
//                          let stateIsAudioCall = audioCall ?? false
//                        
//                        switch result {
//                        case .success(let callDetails):
//                            print("Call Details Successfully Retrieved:")
//                            // Pretty print the JSON
//                            if let prettyData = try? JSONSerialization.data(withJSONObject: callDetails, options: .prettyPrinted),
//                               let prettyString = String(data: prettyData, encoding: .utf8) {
//                                print(prettyString)
//                            }
//                            
//                            // Extract calls array
//                            if let calls = callDetails["calls"] as? [[String: Any]], let firstCall = calls.first {
//                                // Extract specific details
//                                let callType = firstCall["call_type"] as? String ?? "N/A"
//                                let callState = firstCall["state"] as? String ?? "N/A"
//                                
//                                print("Call Type: \(callType)")
//                                print("Call State: \(callState)")
//                                
//                                // Update state on main thread
//                                         DispatchQueue.main.async {
//                                             self.state.url = stateUrl
//                                             self.state.roomId = stateRoomId
//                                             self.state.displayName = stateDisplayName
//                                             self.state.isAudioCall = (callType == "audio")
//                                         }
//                            } else {
//                                print("No Calls Found:")
//                                // No calls found, create a new call
//                                self.createCall(roomId: roomId, userId: userId, isAudioCall: audioCall ?? false)
//                                
//                                // Update state on main thread with default values
//                                        DispatchQueue.main.async {
//                                            self.state.url = stateUrl
//                                            self.state.roomId = stateRoomId
//                                            self.state.displayName = stateDisplayName
//                                            self.state.isAudioCall = stateIsAudioCall
//                                        }
//                            }
//                        
//                        case .failure(let error):
//                            print("Error fetching call details creating new call: \(error.localizedDescription)")
//                            
//                            // Create a new call on failure
//                            self.createCall(roomId: roomId, userId: userId, isAudioCall: audioCall ?? false)
//                            
//                            // Update state on main thread with default values
//                                    DispatchQueue.main.async {
//                                        self.state.url = stateUrl
//                                        self.state.roomId = stateRoomId
//                                        self.state.displayName = stateDisplayName
//                                        self.state.isAudioCall = stateIsAudioCall
//                                    }
//                        }
//                    }
//                   
                    
                 
                    
                    
                case .failure(let error):
                    MXLog.error("Failed starting ElementCall Widget Driver with error: \(error)")
                    state.bindings.alertInfo = .init(id: UUID(),
                                                     title: L10n.errorUnknown,
                                                     primaryButton: .init(title: L10n.actionOk) {
                                                         self.actionsSubject.send(.dismiss)
                                                     })
                    return
                }
                
                await elementCallService.setupCallSession(roomID: roomProxy.id,
                                                          roomDisplayName: roomProxy.infoPublisher.value.displayName ?? roomProxy.id)
            
                if notifyOtherParticipants {
                    _ = await roomProxy.sendCallNotificationIfNeeded()
                }
                
    
           
            }
        }
    }
    
    
    private func handleBackwardsNavigation() async {
        guard state.url != nil,
              isPictureInPictureAllowed,
              let requestPictureInPictureHandler = state.bindings.requestPictureInPictureHandler else {
            actionsSubject.send(.dismiss)
            return
        }
        
        switch await requestPictureInPictureHandler() {
        case .success:
//            print("pictureInPictureStarted==>> requestPictureInPictureHandler")
            actionsSubject.send(.pictureInPictureStarted)
        case .failure:
            actionsSubject.send(.dismiss)
        }
    }
    
    private func setAudioVideoEnabled(enabled: Bool) async {
//        print("setAudioVideoEnabled==> \(enabled)")
        let message = ElementCallWidgetMessage(direction: .toWidget,
                                               action: .mediaState,
                                               data: .init(audioEnabled: enabled, videoEnabled: enabled),
                                               widgetId: widgetDriver.widgetID)
        await postMessageToWidget(message)
    }
    
    private func setAudioEnabled(_ enabled: Bool) async {
//        print("setAudioEnabled VM postMessageToWidget==> \(enabled)")
        let message = ElementCallWidgetMessage(direction: .toWidget,
                                               action: .mediaState,
                                               data: .init(audioEnabled: enabled),
                                               widgetId: widgetDriver.widgetID)
        await postMessageToWidget(message)
    }
    
    func hangup() async {
        let message = ElementCallWidgetMessage(direction: .fromWidget,
                                               action: .hangup,
                                               widgetId: widgetDriver.widgetID)
        
        await postMessageToWidget(message)
    }
    
    private func postMessageToWidget(_ message: ElementCallWidgetMessage) async {
        let data: Data
        do {
            data = try JSONEncoder().encode(message)
        } catch {
            MXLog.error("Failed encoding widget message with error: \(error)")
            return
        }
        
        guard let json = String(data: data, encoding: .utf8) else {
            MXLog.error("Invalid data for widget message")
            return
        }
        
        await postJSONToWidget(json)
    }
    
    private func postJSONToWidget(_ json: String) async {
        
//        print("postJSONToWidget==>: \(json)")
        do {
            let message = "postMessage(\(json), '*')"
            let result = try await state.bindings.javaScriptEvaluator?(message)
            MXLog.debug("Evaluated javascript: \(json) with result: \(String(describing: result))")
        } catch {
            MXLog.error("Received javascript evaluation error: \(error)")
        }
    }
    
    private static let eventHandlerName = "elementx"
    
    private static var eventHandlerInjectionScript: String {
        """
        window.addEventListener(
            "message",
            (event) => {
                let message = {data: event.data, origin: event.origin}
                if (message.data.response && message.data.api == "toWidget"
                || !message.data.response && message.data.api == "fromWidget") {
                  window.webkit.messageHandlers.\(eventHandlerName).postMessage(JSON.stringify(message.data));
                }else{
                  console.log("-- skipped event handling by the client because it is send from the client itself.");
                }
            },
            false,
          );
        """
    }
}
