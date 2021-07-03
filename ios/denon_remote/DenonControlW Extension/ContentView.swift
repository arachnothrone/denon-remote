//
//  ContentView.swift
//  DenonControlW Extension
//
//  Created by Alex Fadeev on 2021-06-20.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State var denonState = MEM_STATE_T()
    @State var volumeString = "unknown"
    @State var scrollAmount = 0.0
    
    @ObservedObject var phoneSession = WatchPhoneConnect()
    
    @State var phoneConnected: Bool = false
    @State var phoneMessageText = "_SND_to_PHONE_"
    @State var cmdString = ""
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    //var cmdString = ""
                    if Int(denonState.power) == 1 {
                        self.cmdString = "CMD05POWEROFF"
                        denonState.power = String(0)
                    } else {
                        self.cmdString = "CMD04POWERON"
                        denonState.power = String(1)
                    }
                    //denonState = sendCommand(cmd: cmdString, rxTO: 1)
                    self.phoneSession.session.sendMessage(["message" : self.cmdString], replyHandler: nil) {(error) in
                        print(error.localizedDescription)
                    }
                    print("watch sent \(self.cmdString) command to the phone")
                },
                       label: {
                        if Int(denonState.power) == 1 {
                            Text("ON").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 48).padding()
                        } else {
                            Text("OFF").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).padding()
                        }
                })
                //.frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: 50, maxWidth: 50, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 50, maxHeight: 50)
                
                Text("\(volumeString)").font(.title).focusable(true).digitalCrownRotation($scrollAmount, from: -20, through: -50, by: -1.0, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
                    // Update the state when application started
                    .onAppear(perform: {
                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
                        volumeString = denonState.volume
                        print("DEBUG: updating volume text: \(volumeString)")
                    })
                    // Update the state when back from background
//                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
//                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
//                        volumeString = denonState.volume
//                    })
            }
            // ----
//            HStack {
//                Button(action: {
//                        var cmdString = ""
//                        if Int(denonState.power) == 1 {
//                            cmdString = "CMD05POWEROFF"
//                        } else {
//                            cmdString = "CMD04POWERON"
//                        }
//                        denonState = sendCommand(cmd: cmdString, rxTO: 1)
//                    },
//                       label: {
//                        if Int(denonState.power) == 1 {
//                            Text("ON").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 48).padding()
//                        } else {
//                            Text("OFF").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).padding()
//                        }
//                })
//                //.frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: 50, maxWidth: 50, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 50, maxHeight: 50)
//
//                Text("\(volumeString)").font(.title).focusable(true).digitalCrownRotation($scrollAmount, from: -20, through: -50, by: -1.0, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
//                    // Update the state when application started
//                    .onAppear(perform: {
//                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
//                        volumeString = denonState.volume
//                        print("DEBUG: updating volume text: \(volumeString)")
//                    })
//                    // Update the state when back from background
////                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
////                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
////                        volumeString = denonState.volume
////                    })
//            }
            
            Text(self.phoneSession.messageText)
            
            HStack {
                Button(action: {phoneConnected = self.phoneSession.session.isReachable; print("DBG: phoneConnected=\(phoneConnected)")}, label: {
                    if phoneConnected == true {
                        Image(systemName: "iphone")
                    } else {
                        Image(systemName: "iphone.slash")
                    }
                })
                
                Button(action: {
                                self.phoneSession.session.sendMessage(["message" : self.phoneMessageText], replyHandler: nil) { (error) in
                                    print(error.localizedDescription)
                                }
                            }) {
                            Text("Send Message")
                            }
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// TODO: remove this, duplicate of iOS app
extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}
