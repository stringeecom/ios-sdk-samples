//
//  InstanceManager.swift
//  CallkitSample-Swift
//
//  Created by Thịnh Giò on 2/10/20.
//  Copyright © 2020 ThinhNT. All rights reserved.
//

import Foundation

class InstanceManager {
    
    static var shared = InstanceManager()
    private init() { }

    private weak var myCallingVC: StringeeCallingVCProtocol?
    var hasRegisteredToReceivePush = false
    
    func showMyCallingVC(with stringeeCall: StringeeCall) {
        guard myCallingVC == nil else { return }
        let isIncomingCall = stringeeCall.isIncomingCall
        let name = isIncomingCall ? stringeeCall.from : stringeeCall.to
        let callingVC = CallingViewController(withUserName: name ?? "Stringee", isIncomingCall: isIncomingCall)
        myCallingVC = callingVC
        callingVC.modalPresentationStyle = .fullScreen
        UIApplication.shared.keyWindow?.rootViewController?.present(callingVC, animated: true, completion: nil)
    }
    
    func myCallingVCUpdateUI(with action: UserCallingAcion, stringeeCall: StringeeCall?) {
        if let call = stringeeCall, action != .end && myCallingVC == nil {
            showMyCallingVC(with: call)
        }
        
        myCallingVC?.updateUI(with: action)
    }
    
    func myCallingVCUpdateUI(for state: SignalingState) {
        myCallingVC?.updateUI(for: state)
    }
    
    func myCallingVCDidChangeMediaState(mediaState: MediaState) {
        myCallingVC?.didChangeMediaState(mediaState: mediaState)
    }
    
    func checkAndUpdateSpeaker(updater: (Bool) -> Void) {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            switch output.portType {
            case .builtInSpeaker:
                updater(true)
                myCallingVC?.updateUI(with: .speaker)
                return
            default: break
            }
        }
        updater(false)
        myCallingVC?.updateUI(with: .speaker)
    }
}
