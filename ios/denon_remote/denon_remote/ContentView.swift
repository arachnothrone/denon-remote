//
//  ContentView.swift
//  denon_remote
//
//  Created by Alex Fadeev on 2021-04-30.
//

import SwiftUI

struct ContentView: View {
    @State var denonState = MEM_STATE_T()
    @State var volumeString = "unknown"
    @State var dimmerImage: Int8 = 0
    @State var imageIndex: Int8 = 0
    @State var dimmerButtonSize: CGFloat = 30
    @State var muteSpeakerImg = "speaker"
    
    @ObservedObject var watchSession = PhoneWatchConnect()
    @State var watchConnected: Bool = false
    @State var messageText = "_SND_"

    var body: some View {
        
        VStack(alignment: .center, spacing: 5) {
            Text("Denon Remote")
                .font(.title)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .padding(10)
                .border(Color.purple, width: 5)

            HStack {
                Text("Vol: \(volumeString) dB").font(.body)
                    // Update the state when application started
                    .onAppear(perform: {
                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
                        volumeString = denonState.volume
                        print("DEBUG: updating volume text: \(volumeString)")
                    })
                    // Update the state when back from background
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
                        denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
                        volumeString = denonState.volume
                    })
                                
                Button(action: {watchConnected = self.watchSession.session.isReachable; print("DBG: watchConnected=\(watchConnected)")}, label: {
                    if watchConnected == true {
                        Image(systemName: "applewatch")
                    } else {
                        Image(systemName: "applewatch.slash")
                    }
                })
                
                Button(action: {
                                self.watchSession.session.sendMessage(["message" : self.messageText], replyHandler: nil) { (error) in
                                    print(error.localizedDescription)
                                }
                            }) {Text("Send Message")}
                Text(self.watchSession.messageText)
            }
            
            //Divider()
            
            HStack {
                Button(action: {denonState = sendCommand(cmd: "CMD04POWERON", rxTO: 1)}, label: {
                        if Int(denonState.power) == 1 {
                            Text("Power ON").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 48).padding()
                        } else {
                            Text("Power ON").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()
                        }
                })
                Button(action: {denonState = sendCommand(cmd: "CMD05POWEROFF", rxTO: 1)}, label: {
                        if Int(denonState.power) == 1 {
                            Text("Power OFF").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()
                        } else {
                        	Text("Power OFF").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).padding()
                        }
                })
            }
            HStack {
                Button(action: {denonState = sendCommand(cmd: "CMD03VOLUMEDOWN", rxTO: 1); volumeString = denonState.volume}, label: {
                    HStack {
                        Text("Down").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Image(systemName: "arrowtriangle.down.fill").foregroundColor(.green).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.yellow)
                    .cornerRadius(40)
                })

                Button(action: {denonState = sendCommand(cmd: "CMD02VOLUMEUP__", rxTO: 1); volumeString = denonState.volume}, label: {
                    HStack {
                        Image(systemName: "arrowtriangle.up.fill").foregroundColor(.orange).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Text("Up").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(40)
                })
            }
            
            Text(" ").font(.body)
            Text("-= Stereo Settings =-").foregroundColor(.black)
            HStack {
                Button(action: {denonState = sendCommand(cmd: "CMD09STANDARD", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 2 && Int(denonState.power) == 1 {
                        Text("STANDARD").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red).glow(color: .red, radius: 24)
                    } else {
                        Text("STANDARD").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red)
                    }
                })
                Button(action: {denonState = sendCommand(cmd: "CMD12DIRECT", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 5 && Int(denonState.power) == 1 {
                        Text("DIRECT").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green).glow(color: .green, radius: 24)
                    } else {
                        Text("DIRECT").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green)
                    }
                })
                Button(action: {denonState = sendCommand(cmd: "CMD13STEREO", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 6 && Int(denonState.power) == 1 {
                        Text("STEREO").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.blue).glow(color: .blue, radius: 24)
                    } else {
                        Text("STEREO").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.blue)
                    }
                })
                Button(action: {denonState = sendCommand(cmd: "CMD075CH7CHSTEREO", rxTO: 1)}, label: {
                    if Int(denonState.stereoMode) == 0 && Int(denonState.power) == 1 {
                        Text("5ch/7ch").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.purple).glow(color: .purple, radius: 24)
                    } else {
                        Text("5ch/7ch").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.purple)
                    }
                })
                
            }
            
            Spacer().frame(height: 10)
            Button(action: {denonState = sendCommand(cmd: "CMD06MUTE", rxTO: 1)
                if Int(denonState.mute) == 0 {
                    muteSpeakerImg = "speaker"
                } else {
                    muteSpeakerImg = "speaker.slash"
                }
            }, label: {
                HStack {
                    Text("Mute").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    Image(systemName: muteSpeakerImg).background(Color.clear).foregroundColor(.blue).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                }
                .padding()
                .foregroundColor(.gray)
                .background(Color.clear)
                .cornerRadius(20)
                .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.gray, lineWidth: 5)
                    )
            })
            
            //Spacer()
            HStack {
                Button(action: {_ = sendCommand(cmd: "CMD01DIMMER", rxTO: 1)
                                dimmerImage += 1
                                imageIndex = dimmerImage % 4
                                print("dimmerImage=\(dimmerImage), imageIndex=\(imageIndex)")
                }) {
                    HStack {
                        switch imageIndex {
                        case 0:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.title.weight(.bold)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        case 1:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.title.weight(.medium)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        case 2:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.title.weight(.light)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        case 3:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.title.weight(.ultraLight)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        default:
                            Image(systemName: "rays").foregroundColor(.green).font(Font.title.weight(.heavy)).padding()
                                .frame(minWidth: dimmerButtonSize, maxWidth: dimmerButtonSize, minHeight: dimmerButtonSize, maxHeight: dimmerButtonSize)
                        }
                    }
                    .cornerRadius(40)
                }
                
                Button(action: {denonState = sendCommand(cmd: "CMD99CALIBRATE_VOL", rxTO: 25); volumeString = denonState.volume}) {
                    Image(systemName: "gearshape").foregroundColor(.red).font(Font.title.weight(.light)).padding()
                }.cornerRadius(40)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension View {
    func glow(color: Color = .red, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
}
