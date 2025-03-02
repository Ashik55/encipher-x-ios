//
//  JitsiMeetViewController.swift
//  jitssss
//
//  Created by Ashikur Rahman on 23/2/25.
//


import SwiftUI
import JitsiMeetSDK

struct JitsiMeetViewController: UIViewControllerRepresentable {
     var roomName: String
     var displayName: String
     var isAudioCall: Bool
    var onCallEnded: (() -> Void)?  // Make this optional
    

    func makeUIViewController(context: Context) -> JitsiMeetViewControllerWrapper {
        let viewController = JitsiMeetViewControllerWrapper()
        viewController.roomName = roomName
        viewController.displayName = displayName
        viewController.isAudioCall = isAudioCall
        viewController.onCallEnded = onCallEnded
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: JitsiMeetViewControllerWrapper, context: Context) {
        uiViewController.roomName = roomName
   
    }
}

class JitsiMeetViewControllerWrapper: UIViewController {
    var roomName: String = ""
    var displayName: String = ""
    var isAudioCall = false
    var onCallEnded: (() -> Void)?  // Callback for call end

    
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userInfo = JitsiMeetUserInfo()
        userInfo.displayName = displayName // Set the desired display name here

        
        let defaultOptions = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.serverURL = URL(string: "https://meet.enciph-er.com")
            builder.userInfo = userInfo // Set the user info here
            
            builder.setAudioOnly(self.isAudioCall)
            
            builder.setFeatureFlag("welcomepage.enabled", withValue: false)
            builder.setFeatureFlag("prejoinpage.enabled", withValue: false)
            
            
             // Try setting the audio device flag
             builder.setFeatureFlag("video-share.enabled", withValue: self.isAudioCall)
             builder.setFeatureFlag("toolbox.alwaysVisible", withValue: false)
             builder.setFeatureFlag("reactions.enabled", withValue: false)
             builder.setFeatureFlag("chat.enabled", withValue: false)
            
            
            //audio video call
//            builder.setAudioOnly(self.isAudioCall) // Explicitly use `self`
//            builder.setVideoMuted(self.isAudioCall)
            
     
            
            
        }
        
        JitsiMeet.sharedInstance().defaultConferenceOptions = defaultOptions
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Create and configure JitsiMeetView
        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView
        
        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = self.roomName
        }
        
        jitsiMeetView.join(options)

        // Enable PiP mode
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: view)
        
        // Animate in
        jitsiMeetView.alpha = 0
        pipViewCoordinator?.show()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let rect = CGRect(origin: CGPoint.zero, size: size)
        pipViewCoordinator?.resetBounds(bounds: rect)
    }
    
    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
    }
}

extension JitsiMeetViewControllerWrapper: JitsiMeetViewDelegate {
    func ready(toClose data: [AnyHashable : Any]!) {
        pipViewCoordinator?.hide() { _ in
            self.cleanUp()
            self.onCallEnded?()  // Notify the parent view to navigate back
        }
    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        pipViewCoordinator?.enterPictureInPicture()
    }
}
