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
    @State var volumeString = "unknown"
    @State var volumeString2 = ""
    @State var muteSpeakerImg = "speaker"
    @State var dimmerImage: Int8 = 0
    @State var imageIndex: Int8 = 0
    @State var dimmerButtonSize: CGFloat = 20
    @State var scrollAmount = 40.0
    @State var scrollAmountPrev = 40.0
    
    @ObservedObject var phoneSession = WatchPhoneConnect()
    
    @State var phoneConnected: Bool = false
    @State var phoneMessageText = "_SND_to_PHONE_"
    @State var cmdString = ""
    @State var msg2reply = "*"
    @State var replyStr: String = ""
    
    // =================================
//    @State var date: Date = Date()
//    @State var scroll: Double = 0.0
//    @State var scrolling: Bool = false
    
    private let relay = PassthroughSubject<Double, Never>()
    private let debouncedPublisher: AnyPublisher<Double, Never>
    init() {
        debouncedPublisher = relay
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
//    var body: some View {
//        VStack {
//            Text("\(date)")
//                .focusable(true)
//                .opacity(scrolling ? 1 : 0)
//                .digitalCrownRotation($scroll, from: 0, through: 365, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
//                .onChange(of: scroll) { value in
//                    withAnimation {
//                        scrolling = true
//                    }
//                    relay.send(value)
//                    print("+++ \(value)")
//                    date = Calendar.current.date(byAdding: .day, value: Int(value), to: Date())!
//                }
//                .onReceive(
//                    debouncedPublisher,
//                    perform: { value in
//                        withAnimation {
//                            scrolling = false
//                        }
//                        print("--------->>>>>> \(value)")
//                    }
//                )
//        }
////        .onAppear {
////            self.date = Date()
////        }
//    }
    // ============================
    
    func sendMessageToPhone(msgString: String) -> MEM_STATE_T {
        var result: MEM_STATE_T = MEM_STATE_T()
        self.phoneSession.session.sendMessage(["wMessage": msgString], replyHandler:
        {
            reply in replyStr = reply["pMessage"] as! String
            print("# ---> recvd reply = \(reply)")
            print("# --->>> replyStr = \(replyStr)")
            result = deserializeDenonState(ds_string: replyStr)
            denonState = deserializeDenonState(ds_string: replyStr)
            volumeString = denonState.volume
        }, errorHandler: {(error) in print("# ---> error=\(error)")})
        print("# watch sent \(msgString) command to the phone")
        return result
    }
    
    var body: some View {
        VStack {
            // --- Power button and Volume crown ------------------------------------------
            HStack {
                Button(action: {
                    if Int(denonState.power) == 1 {
                        self.cmdString = "CMD05POWEROFF"
                    } else {
                        self.cmdString = "CMD04POWERON"
                    }
                    print("watch sent \(self.cmdString) command to the phone")
                    denonState = self.sendMessageToPhone(msgString: self.cmdString)
                    volumeString = denonState.volume
                },
                   label: {
                    if Int(denonState.power) == 1 {
                        Text("ON").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 48).padding()
                    } else {
                        Text("OFF").font(.body).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).padding()
                    }
                })
                //.frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealWidth: 50, maxWidth: 50, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: 50, maxHeight: 50)

                Text("\(volumeString2)")
                    .font(.body)
                    .focusable(true)
                    .digitalCrownRotation($scrollAmount, from: 0, through: 50, sensitivity: DigitalCrownRotationalSensitivity.medium)
                    .onChange(of: scrollAmount, perform: {value in
                        volumeString = String(Int(value) * -1)
                        //print(String(format: "DC val: %.3f, \(volumeString)", value))
                        relay.send(value)
                    })
                    .onReceive(debouncedPublisher, perform: {value in
                        let diff = scrollAmountPrev - value
                        scrollAmountPrev = value
                        let valueDiff = String(Int(diff))
                        print("---> ready to send command to RPi \(valueDiff)")
                        // let volumeDiff = denonState.volume
                        denonState = self.sendMessageToPhone(msgString: "CMD98GET_STATE")
                        print(denonState)
                    })
                    // Update the state when application started
//                    .onAppear(perform: {
//                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
//                        volumeString = denonState.volume
//                        print("DEBUG: updating volume text: \(volumeString)")
//                    })
                    // Update the state when back from background
                    .onChange(of: scene_phase, perform: { value in
                        if value == .active {
                            print("=====>>>>> app returned from background, in foreground now - request denon state update")
                            denonState = self.sendMessageToPhone(msgString: "CMD98GET_STATE")
                            volumeString = denonState.volume
                            scrollAmount = Double(denonState.volume) ?? -47.0
                            scrollAmountPrev = Double(denonState.volume) ?? -47.0
                        } else if value == .background {
                            print("=====>>>>> app is in the background")
                        } else if value == .inactive {
                            print("======>>>> inactive - app on the screen but watch is displaying digital time")
                        }
                    })
                    .onChange(of: volumeString, perform: {value in volumeString2 = value})
//                    .onChange(of: scrollAmount, perform: { value in
//                        print("...\(round(scrollAmount))")
//                    })
            }
            // --- Sound mode buttons 4x ------------------------------------------
            HStack {
                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD09STANDARD")}, label: {
                    if Int(denonState.stereoMode) == 2 && Int(denonState.power) == 1 {
                        Text("Std").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.red)//.glow(color: .red, radius: 24)
                    } else {
                        Text("Std").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.red)//.font(.body).fontWeight(.medium).foregroundColor(.red)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)//.scaledToFit()//.buttonStyle(DefaultButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD12DIRECT")}, label: {
                    if Int(denonState.stereoMode) == 5 && Int(denonState.power) == 1 {
                        Text("Direct").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.green)//.glow(color: .green, radius: 24)
                    } else {
                        Text("Direct").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.green)//.font(.body).fontWeight(.medium).foregroundColor(.green)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)//.scaledToFit()//.buttonStyle(DefaultButtonStyle())
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//            }//.scaledToFit()
                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD13STEREO")}, label: {
                    if Int(denonState.stereoMode) == 6 && Int(denonState.power) == 1 {
                        Text("Stereo").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.blue).glow(color: .blue, radius: 24)
                    } else {
                        Text("Stereo").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.blue)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD075CH7CHSTEREO")}, label: {
                    if Int(denonState.stereoMode) == 0 && Int(denonState.power) == 1 {
                        Text("5ch7ch").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.purple).glow(color: .purple, radius: 24)
                    } else {
                        Text("5ch7ch").font(.custom("Arial", size: 12)).fontWeight(.medium).foregroundColor(.purple)
                    }
                })//.scaleEffect(CGSize(width: 0.7, height: 0.7), anchor: .center)
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
            HStack {
                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD06MUTE")
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

                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD01DIMMER")
                                //dimmerImage += 1
                    imageIndex = Int8(denonState.dimmer) ?? 0 // dimmerImage % 4
                                print("Dimmer=\(denonState.dimmer) imageIndex=\(imageIndex)")
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

                Button(action: {denonState = self.sendMessageToPhone(msgString: "CMD99CALIBRATE_VOL"); volumeString = denonState.volume}) {
                    Image(systemName: "gearshape").foregroundColor(.red).font(Font.body.weight(.light)).padding()
                        //.frame(minWidth: muteButtonSize, maxWidth: muteButtonSize, minHeight: muteButtonSize, maxHeight: muteButtonSize)
                }
                .cornerRadius(40)
            }
        }
        .onAppear(perform: {
            let cmd = "CMD98GET_STATE"
            denonState = self.sendMessageToPhone(msgString: cmd)
            volumeString = denonState.volume
            scrollAmountPrev = Double(denonState.volume) ?? -43.0
            scrollAmount = Double(Int(denonState.volume) ?? -44)
            print("watch sent \(cmd) command to the phone")
            print("denonState=\(denonState), scroolAmount=\(scrollAmount)")
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
