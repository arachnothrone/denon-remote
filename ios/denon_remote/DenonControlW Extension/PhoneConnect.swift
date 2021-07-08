//
//  PhoneConnect.swift
//  DenonControlW Extension
//
//  Created by Alex Fadeev on 2021-06-29.
//

import Foundation
import WatchConnectivity

class WatchPhoneConnect: NSObject,  WCSessionDelegate, ObservableObject {
    var session: WCSession
    @Published var messageText = "0,-44,1,0,0,0"
    
    init(session: WCSession = .default){
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.messageText = message["message"] as? String ?? "Unknown"
            print("Watch received message: \(self.messageText)", terminator: "\n")
        }
    }
    
}
