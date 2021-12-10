//
//  WatchConnect.swift
//  denon_remote
//
//  Created by Alex Fadeev on 2021-06-29.
//

import Foundation
import WatchConnectivity

class PhoneWatchConnect: NSObject,  WCSessionDelegate, ObservableObject {
    var session: WCSession
    @Published var messageText = ":::"
    
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    }
    
    // Called when a message is received and the peer needs a response.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        let watchCommand = message["wMessage"] as? String ?? "Unknown"
        let raspiResult = sendCommandW(cmd: watchCommand, rxTO: 5)
        print("watchCommand execution result (Raspi reply): \(raspiResult)")
        // forward Raspi response back to the Watch
        replyHandler(["pMessage": raspiResult])
    }
}
