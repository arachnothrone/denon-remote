//
//  WatchConnect.swift
//  denon_remote
//
//  Created by Alex Fadeev on 2021-06-29.
//

import Foundation
import WatchConnectivity

class PhoneWatchConnect: NSObject,  WCSessionDelegate {
    var session: WCSession
    init(session: WCSession = .default){
            self.session = session
            super.init()
            self.session.delegate = self
            session.activate()
        }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

    }

    func sessionDidBecomeInactive(_ session: WCSession) {

    }

    func sessionDidDeactivate(_ session: WCSession) {

    }
    
//    var session: WCSession
//    @Published var messageText = ""
//    init(session: WCSession = .default){
//        self.session = session
//        super.init()
//        self.session.delegate = self
//        session.activate()
//    }
//    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//
//    }
//    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
//        DispatchQueue.main.async {
//            self.messageText = message["message"] as? String ?? "Unknown"
//        }
//    }
    
    
}
