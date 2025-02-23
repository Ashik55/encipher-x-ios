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
    
    func makeUIViewController(context: Context) -> JitsiMeetViewControllerWrapper {
        let viewController = JitsiMeetViewControllerWrapper()
        viewController.roomName = roomName
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: JitsiMeetViewControllerWrapper, context: Context) {
        uiViewController.roomName = roomName
   
    }
}

class JitsiMeetViewControllerWrapper: UIViewController {
    var roomName: String = ""

    
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultOptions = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.serverURL = URL(string: "https://meet.jit.si")
            builder.setFeatureFlag("welcomepage.enabled", withValue: false)
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
        }
    }
    
    func enterPicture(inPicture data: [AnyHashable : Any]!) {
        pipViewCoordinator?.enterPictureInPicture()
    }
}
