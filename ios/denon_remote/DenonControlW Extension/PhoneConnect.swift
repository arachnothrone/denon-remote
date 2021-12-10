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
    }
}

// TODO: Need to wait for reply, now it returns before reply received
func phoneCommand(ssn: WatchPhoneConnect, cmd: String) -> String {

    var replyStr: String = "mmm"

    ssn.session.sendMessage(
        ["wMessage": cmd],
        replyHandler: {
            reply in replyStr = reply["pMessage"] as! String
            print("---> recvd reply = \(reply)")
        },
        errorHandler: {(error) in print("---> error=\(error)")}
    )
    
    return replyStr
}
