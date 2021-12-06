//
//  ContentView.swift
//  DenonControlW Extension
//
//  Created by Alex Fadeev on 2021-06-20.
//

import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @Environment(\.scenePhase) var scene_phase
    @State var denonState = MEM_STATE_T()
    @State var powerCommand = "CMD04POWERON"
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
        
    private let relay = PassthroughSubject<Double, Never>()
    private let debouncedPublisher: AnyPublisher<Double, Never>
    init() {
        debouncedPublisher = relay
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    func sendMessageToPhone(msgString: String) -> Void {
        self.phoneSession.session.sendMessage(["wMessage": msgString], replyHandler:
        {
            reply in replyStr = reply["pMessage"] as! String
            print("\(getTimeStamp()) # ---> recvd reply = \(reply)")
            print("\(getTimeStamp()) # --->>> replyStr = \(replyStr)")
            self.denonState = deserializeDenonState(ds_string: replyStr)
        }, errorHandler: {(error) in print("\(getTimeStamp()) # ---> error=\(error)")})
    }

    var body: some View {
        VStack {
            // --- Power button and Volume crown ------------------------------------------
            HStack {
                // Power button
                Button(action: {
                    sendMessageToPhone(msgString: self.powerCommand)
                },
                   label: {
                    if Int(denonState.power) == 1 {
                        Text("ON").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 48).padding()
                    } else {
                        Text("OFF").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).padding()
                    }
                    //self.powerLabel
                })
                .onChange(of: denonState.power, perform: {value in
                    let ts = getTimeStamp()
                    print("\(ts) Onchange Power button = \(value)")
                    
                    if Int(denonState.power) == 1 {
                        self.powerCommand = "CMD05POWEROFF"
                        //self.powerLabel = Text("ON").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 48).padding()
                    } else {
                        self.powerCommand = "CMD04POWERON"
                        //self.powerLabel = Text("OFF").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).padding() as! Text
                    }
                })
                //.frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: 50, maxWidth: 50, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 50, maxHeight: 50)

                // Volume value
                Text("\(volumeString)")
                    .font(.body)
                    .focusable(true)
                    .digitalCrownRotation($scrollAmount, from: 0, through: 60, sensitivity: DigitalCrownRotationalSensitivity.medium)
                    .onChange(of: scrollAmount, perform: {value in
                        volumeString = String(Int(value) * -1)
                        relay.send(value)
                    })
                    .onReceive(debouncedPublisher, perform: {value in
                        print(denonState.volume, value, Int(value))
                        let diff = (Int(denonState.volume) ?? (-40)) - (Int(value) * (-1))
                        print(diff)
                        var cmdCode: Int = 19
                        var cmdName: String = "DECREASE"
                        if diff < 0 {
                            cmdCode = 18
                            cmdName = "INCREASE"
                        } else {
                            cmdCode = 19
                            cmdName = "DECREASE"
                        }
                        let cmd = String(format: "CMD%02d\(cmdName)VOL%02d", cmdCode, abs(diff))
                        print("\(getTimeStamp()) ---> ready to send command to RPi: \(cmd)")
                        self.sendMessageToPhone(msgString: cmd)
                        //self.sendMessageToPhone2(msgString: "CMD98GET_STATE")
                        //print(denonState)
                    })
                    // Update the state when back from background
                    .onChange(of: scene_phase, perform: { value in
                        if value == .active {
                            print("\(getTimeStamp()) ===> app returned from background, in foreground now - request denon state update")
                            self.sendMessageToPhone(msgString: "CMD98GET_STATE")
                        } else if value == .background {
                            print("\(getTimeStamp()) ===> app is in the background")
                        } else if value == .inactive {
                            print("\(getTimeStamp()) ===> inactive - app on the screen but watch is displaying digital time")
                        }
                    })
                    .onChange(of: denonState.volume, perform: {value in volumeString = value; print("Updating vol to \(value)")})
            }
            // --- Sound mode buttons 4x ------------------------------------------
            HStack {
                Button(action: {self.sendMessageToPhone(msgString: "CMD09STANDARD")}, label: {
                    if Int(denonState.stereoMode) == 2 && Int(denonState.power) == 1 {
                        Text("Std").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.red).glow(color: .red, radius: 24)
                    } else {
                        Text("Std").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.red)//.font(.body).fontWeight(.medium).foregroundColor(.red)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)//.scaledToFit()//.buttonStyle(DefaultButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                Button(action: {self.sendMessageToPhone(msgString: "CMD12DIRECT")}, label: {
                    if Int(denonState.stereoMode) == 5 && Int(denonState.power) == 1 {
                        Text("Direct").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.green).glow(color: .green, radius: 24)
                    } else {
                        Text("Direct").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.green)//.font(.body).fontWeight(.medium).foregroundColor(.green)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)//.scaledToFit()//.buttonStyle(DefaultButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//            }//.scaledToFit()
                Button(action: {self.sendMessageToPhone(msgString: "CMD13STEREO")}, label: {
                    if Int(denonState.stereoMode) == 6 && Int(denonState.power) == 1 {
                        Text("Stereo").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.blue).glow(color: .blue, radius: 24)
                    } else {
                        Text("Stereo").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.blue)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                Button(action: {self.sendMessageToPhone(msgString: "CMD075CH7CHSTEREO")}, label: {
                    if Int(denonState.stereoMode) == 0 && Int(denonState.power) == 1 {
                        Text("5ch7ch").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.purple).glow(color: .purple, radius: 24)
                    } else {
                        Text("5ch7ch").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.purple)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
            
            // Mute, dimmer, calibration buttons
            HStack {
                Button(action: {self.sendMessageToPhone(msgString: "CMD06MUTE")
//                    if Int(denonState.mute) == 1 {
//                        muteSpeakerImg = "speaker.slash"
//                    } else {
//                        muteSpeakerImg = "speaker"
//                    }
                }, label: {
                    HStack {
                        //Text("Mute").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Image(systemName: self.muteSpeakerImg).background(Color.clear).foregroundColor(.blue).font(Font.body.weight(.medium))
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
                .onChange(of: denonState.mute, perform: {mute in
                    if Int(mute) == 1 {
                        self.muteSpeakerImg = "speaker.slash"
                    } else {
                        self.muteSpeakerImg = "speaker"
                    }
                })

                // Mute button
                Button(action: {self.sendMessageToPhone(msgString: "CMD01DIMMER")
                                //dimmerImage += 1
                    imageIndex = Int8(denonState.dimmer) ?? 0 // dimmerImage % 4
                                print("\(getTimeStamp()) Dimmer=\(denonState.dimmer) imageIndex=\(imageIndex)")
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

                // Calibration button
                Button(action: {self.sendMessageToPhone(msgString: "CMD99CALIBRATE_VOL"); volumeString = denonState.volume}) {
                    Image(systemName: "gearshape").foregroundColor(.red).font(Font.body.weight(.light)).padding()
                        //.frame(minWidth: muteButtonSize, maxWidth: muteButtonSize, minHeight: muteButtonSize, maxHeight: muteButtonSize)
                }
                .cornerRadius(40)
            }
        }
        .onAppear(perform: {
            print("\(getTimeStamp()) -----> APPEAR")
            let cmd = "CMD98GET_STATE"
            self.sendMessageToPhone(msgString: cmd)
        })
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
