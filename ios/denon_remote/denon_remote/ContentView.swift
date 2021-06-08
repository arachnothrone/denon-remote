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

    var body: some View {
        
//        Text("Denon Remote")
//            .font(.title)
//            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//            .padding()
//            .background(Color.purple)
//            .foregroundColor(.white)
//            .padding(10)
//            .border(Color.purple, width: 5)
        VStack(alignment: .center, spacing: 5) {
            Text("Denon Remote")
                .font(.title)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .padding(10)
                .border(Color.purple, width: 5)
//            Text(" ").font(.body)
            Text("Vol: \(volumeString) dB").font(.body)
                .onAppear(perform: {
                    denonState = sendCommand(cmd: "CMD98GET_STATE", rxTO: 1)
                    volumeString = denonState.volume
                    print("DEBUG: updating volume text: \(volumeString)")
                })
            //Divider()
            
            HStack {
                Button(action: {_ = sendCommand(cmd: "CMD04POWERON", rxTO: 1)}, label: {
                        Text("Power ON").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()})
                Button(action: {_ = sendCommand(cmd: "CMD05POWEROFF", rxTO: 1)}, label: {
                        Text("Power OFF").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()})
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
//                Button("vol.down") {
//                    ss = udpSendString(textToSend: "CMD03VOLUMEDOWN", address: "192.168.2.101", port: 19001)
//                }
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
                Button(action: {_ = sendCommand(cmd: "CMD09STANDARD", rxTO: 1)}, label: {
                    Text("STANDARD").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red)
                })
                Button(action: {_ = sendCommand(cmd: "CMD12DIRECT", rxTO: 1)}, label: {
                    Text("DIRECT").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green)
                })
                Button(action: {_ = sendCommand(cmd: "CMD13STEREO", rxTO: 1)}, label: {
                    Text("STEREO").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.blue)
                })
                Button(action: {_ = sendCommand(cmd: "CMD075CH7CHSTEREO", rxTO: 1)}, label: {
                    Text("5ch/7ch").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.purple)
                })
                
            }
            
            //Text(" ").font(.body)
            Spacer().frame(height: 10)
            Button(action: {denonState = sendCommand(cmd: "CMD06MUTE", rxTO: 1)
                if Int(denonState.mute) == 1 {
                    muteSpeakerImg = "speaker"
                } else {
                    muteSpeakerImg = "speaker.slash"
                }
            }, label: {
                HStack {
                    Text("Mute").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    Image(systemName: muteSpeakerImg).background(Color.clear).foregroundColor(.blue).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                }
                //.border(Color.purple, width: 5)
                .padding()
                .foregroundColor(.gray)
                .background(Color.clear)
                //.border(Color.purple, width: 5)
                .cornerRadius(20)
                //.padding()
                //.border(Color.purple, width: 5)
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
                        //Image(systemName: "rays").foregroundColor(.green).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).padding()
                        
                    }
                    .cornerRadius(40)
                }
                
                Button(action: {denonState = sendCommand(cmd: "CMD99CALIBRATE_VOL", rxTO: 25); volumeString = denonState.volume}) {
                    Image(systemName: "gearshape").foregroundColor(.red).font(Font.title.weight(.light)).padding()
                        //.frame(minWidth: muteButtonSize, maxWidth: muteButtonSize, minHeight: muteButtonSize, maxHeight: muteButtonSize)
                }.cornerRadius(40)
            }
//            Button(action: {udpSendString(textToSend: "CMD01DIMMER", address: "192.168.2.101", port: 19001)}) {
//                HStack {
//                    //Text("Dimmer").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
//                    Image(systemName: "rays").foregroundColor(.green).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).padding()
//                }
//                .cornerRadius(40)
//
//            }
            
//            HStack {
//                Button(action: {udpSendString(textToSend: "CMD99CALIBRATE_VOL", address: "192.168.2.101", port: 19001)}) {
//                    ///*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
//                    Image(systemName: "gearshape")
//                }
//            }
        }
    }
    //.onAppear {volumeString = udpSendString(textToSend: "CMD98GET_STATE", address: "192.168.2.101", port: 19001, rxTimeoutSec: 1)}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
