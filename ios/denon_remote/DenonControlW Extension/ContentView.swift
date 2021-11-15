//
//  ContentView.swift
//  DenonControlW Extension
//
//  Created by Alex Fadeev on 2021-06-20.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @Environment(\.scenePhase) var scene_phase
    @State var denonState = MEM_STATE_T()
    @State var volumeString = "unknown"
    @State var muteSpeakerImg = "speaker"
    @State var dimmerImage: Int8 = 0
    @State var imageIndex: Int8 = 0
    @State var dimmerButtonSize: CGFloat = 20
    @State var scrollAmount = 0.0
    
    @ObservedObject var phoneSession = WatchPhoneConnect()
    
    @State var phoneConnected: Bool = false
    @State var phoneMessageText = "_SND_to_PHONE_"
    @State var cmdString = ""
    @State var msg2reply = "*"
    @State var replyStr: String = ""
    
    var body: some View {
        VStack {
            // --- Power button and Volume crown ------------------------------------------
            HStack {
                Button(action: {
                    //var cmdString = ""
                    if Int(denonState.power) == 1 {
                        self.cmdString = "CMD05POWEROFF"
                        //denonState.power = String(0)
                    } else {
                        self.cmdString = "CMD04POWERON"
                        //denonState.power = String(1)
                    }
                    //denonState = sendCommand(cmd: cmdString, rxTO: 1)
//                    self.phoneSession.session.sendMessage(["message" : self.cmdString], replyHandler: nil) {(error) in
//                        print(error.localizedDescription)
//                    }
                    
                    
                    self.phoneSession.session.sendMessage(["wMessage": self.cmdString], replyHandler:
                    //self.phoneSession.session.sendMessage(["wMessage": "CMD98GET_STATE"], replyHandler:
                                                            {
                        reply in replyStr = reply["pMessage"] as! String
                        print("---> recvd reply = \(reply)")
                        print("--->>> replyStr = \(replyStr)")
                        denonState = deserializeDenonState(ds_string: replyStr)
                        volumeString = denonState.volume
                    }, errorHandler: {(error) in print("---> error=\(error)")})
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
                
                Text("\(volumeString)").font(.body).focusable(true).digitalCrownRotation($scrollAmount, from: -20, through: -50, by: -1.0, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
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
                    .onChange(of: scene_phase, perform: { value in
                        if value == .active {
                            print("=====>>>>> app returned from background, in foreground now - request denon state update")
                            self.phoneSession.session.sendMessage(["wMessage": "CMD98GET_STATE"], replyHandler: {
                                reply in replyStr = reply["pMessage"] as! String
                                denonState = deserializeDenonState(ds_string: replyStr)
                                volumeString = denonState.volume
                            })
                        } else if value == .background {
                            print("=====>>>>> app is in the background")
                        } else if value == .inactive {
                            print("======>>>> inactive - app on the screen but watch is displaying digital time")
                        }
                    })
            }
            // --- Sound mode buttons 4x ------------------------------------------
            HStack {
                Button(action: {denonState = sendCommand(cmd: "CMD09STANDARD", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 2 && Int(denonState.power) == 1 {
                        Text("Std").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.red)//.glow(color: .red, radius: 24)
                    } else {
                        Text("Std").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.red)//.font(.body).fontWeight(.medium).foregroundColor(.red)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)//.scaledToFit()//.buttonStyle(DefaultButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                Button(action: {denonState = sendCommand(cmd: "CMD12DIRECT", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 5 && Int(denonState.power) == 1 {
                        Text("Direct").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.green)//.glow(color: .green, radius: 24)
                    } else {
                        Text("Direct").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.green)//.font(.body).fontWeight(.medium).foregroundColor(.green)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)//.scaledToFit()//.buttonStyle(DefaultButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//            }//.scaledToFit()
// Uncomment for two buttons in a row, otherwise four in a row
//            HStack {
                Button(action: {denonState = sendCommand(cmd: "CMD13STEREO", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 6 && Int(denonState.power) == 1 {
                        Text("Stereo").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.blue).glow(color: .blue, radius: 24)
                    } else {
                        Text("Stereo").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.blue)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                Button(action: {denonState = sendCommand(cmd: "CMD075CH7CHSTEREO", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 0 && Int(denonState.power) == 1 {
                        Text("5ch7ch").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.purple).glow(color: .purple, radius: 24)
                    } else {
                        Text("5ch7ch").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.purple)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
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
            
            
//            Text(self.phoneSession.messageText).font(.body)
//            Text(msg2reply).font(.body)
              
              // temp buttons: phone connection and send/receive to phone message test button
//            HStack {
//                Button(action: {phoneConnected = self.phoneSession.session.isReachable; print("DBG: phoneConnected=\(phoneConnected)")}, label: {
//                    if phoneConnected == true {
//                        Image(systemName: "iphone")
//                    } else {
//                        Image(systemName: "iphone.slash")
//                    }
//                })
//
//                Button(action: {
////                    self.phoneSession.session.sendMessage(["wMessage": "CMD98GET_STATE"], replyHandler: {reply in print("Received reply=\(reply["pMessage"] ?? "=== === ===")")}, errorHandler: {(error) in print("---> error=\(error)")})
//                    // TODO: replace with the wrapper
//                    self.phoneSession.session.sendMessage(["wMessage": "CMD98GET_STATE"], replyHandler: {
//                        reply in replyStr = reply["pMessage"] as! String
//                        print("---> recvd reply = \(reply)")
//                    }, errorHandler: {(error) in print("---> error=\(error)")})
////                    // TODO: Find why it doesn't wait for reply
////                    self.replyStr = phoneCommand(ssn: self.phoneSession, cmd: "CMD98GET_STATE")
////                        print("btn recvd: \(self.replyStr)")
//                    })
//                {
//                //Text("Send Message")
//                    Text(self.replyStr)
//                }
//            } // --------------------------------------------------------------------------------------------
            HStack {
                Button(action: {denonState = sendCommand(cmd: "CMD06MUTE", rxTO: 1)
                    if Int(denonState.mute) == 1 {
                        muteSpeakerImg = "speaker.slash"
                    } else {
                        muteSpeakerImg = "speaker"
                    }
                }, label: {
                    HStack {
                        //Text("Mute").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Image(systemName: muteSpeakerImg).background(Color.clear).foregroundColor(.blue).font(Font.body.weight(.medium))
                    }
                    //.border(Color.purple, width: 5)
                    .padding()
                    .foregroundColor(.gray)
                    .background(Color.clear)
                    //.border(Color.purple, width: 5)
                    //.cornerRadius(20)
                    //.padding()
                    //.border(Color.purple, width: 5)
//                    .overlay(
//                            RoundedRectangle(cornerRadius: 40)
//                                .stroke(Color.gray, lineWidth: 5)
//                        )
                })
                
                Button(action: {_ = sendCommand(cmd: "CMD01DIMMER", rxTO: 1)
                                dimmerImage += 1
                                imageIndex = dimmerImage % 4
                                print("dimmerImage=\(dimmerImage), imageIndex=\(imageIndex)")
                }, label: {
                        switch imageIndex {
                        case 0:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.body.weight(.bold)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        case 1:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.body.weight(.medium)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        case 2:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.body.weight(.light)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        case 3:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.body.weight(.ultraLight)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        default:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.body.weight(.heavy)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        }
                })
                
                Button(action: {denonState = sendCommand(cmd: "CMD99CALIBRATE_VOL", rxTO: 25); volumeString = denonState.volume}) {
                    Image(systemName: "gearshape").foregroundColor(.red).font(Font.body.weight(.light)).padding()
                        //.frame(minWidth: muteButtonSize, maxWidth: muteButtonSize, minHeight: muteButtonSize, maxHeight: muteButtonSize)
                }
                .cornerRadius(40)
            }
        }
//        .onAppear(perform: {
//            let cmd = "CMD98GET_STATE"
//            
////            self.phoneSession.session.sendMessage(["message": cmd], replyHandler: nil {(error) in
////                print(error.localizedDescription)
////            }
//            self.phoneSession.session.sendMessage(["message": cmd], replyHandler: {reply in replyStr = reply["message2"] as! String; print("Received reply=\(reply)")}, errorHandler: {(error) in print("---> error=\(error)")})
//            print("watch sent \(cmd) command to the phone")
//            print("reply received replyStr=\(replyStr)")
//            denonState = deserializeDenonState(ds_string: self.phoneSession.messageText)
//        })
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
