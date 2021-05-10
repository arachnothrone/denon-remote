//
//  ContentView.swift
//  denon_remote
//
//  Created by Alex Fadeev on 2021-04-30.
//

import SwiftUI

struct ContentView: View {
    var ss = ""
    var body: some View {
        
//        Text("Denon Remote")
//            .font(.title)
//            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
//            .padding()
//            .background(Color.purple)
//            .foregroundColor(.white)
//            .padding(10)
//            .border(Color.purple, width: 5)
        VStack (alignment: .center, spacing: 5){
            Text("Denon Remote")
                .font(.title)
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .padding(10)
                .border(Color.purple, width: 5)
//            Text(" ").font(.body)
//            Text(" ").font(.body)
            Divider()
            
            HStack {
                Button(action: {udpSendString(textToSend: "CMD04POWERON", address: "192.168.2.101", port: 19001)}, label: {
                        Text("Power ON").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()})
                Button(action: {udpSendString(textToSend: "CMD05POWERON", address: "192.168.2.101", port: 19001)}, label: {
                        Text("Power OFF").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()})
            }
            HStack {
                Button(action: {udpSendString(textToSend: "CMD03VOLUMEDOWN", address: "192.168.2.101", port: 19001)}, label: {
                    HStack {
                        Text("Down").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Image(systemName: "arrowtriangle.down.fill").foregroundColor(.green).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.yellow)
                    .cornerRadius(40)
                })
                Button(action: {udpSendString(textToSend: "CMD02VOLUMEUP__", address: "192.168.2.101", port: 19001)}, label: {
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
            
            Text(" ").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            Text("-= Stereo Settings =-").foregroundColor(.black)
            HStack {
                Button(action: {udpSendString(textToSend: "CMD09STANDARD", address: "192.168.2.101", port: 19001)}, label: {
                    Text("STANDARD").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.red)
                })
                Button(action: {udpSendString(textToSend: "CMD12DIRECT", address: "192.168.2.101", port: 19001)}, label: {
                    Text("DIRECT").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.green)
                })
                Button(action: {udpSendString(textToSend: "CMD13STEREO", address: "192.168.2.101", port: 19001)}, label: {
                    Text("STEREO").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.blue)
                })
                Button(action: {udpSendString(textToSend: "CMD075CH7CHSTEREO", address: "192.168.2.101", port: 19001)}, label: {
                    Text("5ch/7ch").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.purple)
                })
                
            }
            
            Text(" ").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            Button(action: {udpSendString(textToSend: "CMD06MUTE", address: "192.168.2.101", port: 19001)}, label: {
                HStack {
                    Text("Mute").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    Image(systemName: "speaker.slash").background(Color.clear).foregroundColor(.blue).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
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
            
            Button(action: {udpSendString(textToSend: "CMD01DIMMER", address: "192.168.2.101", port: 19001)}) {
                HStack {
                    //Text("Dimmer").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    Image(systemName: "rays").foregroundColor(.green).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).padding()
                }
                .cornerRadius(40)

            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
