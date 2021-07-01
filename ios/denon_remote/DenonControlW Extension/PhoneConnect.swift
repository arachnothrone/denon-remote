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
    init(session: WCSession = .default){
        self.session = session
        super.init()
        self.session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
}
