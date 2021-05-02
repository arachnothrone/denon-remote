//
//  ContentView.swift
//  denon_remote
//
//  Created by Alex Fadeev on 2021-04-30.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        Text("Denon Remote")
            .font(.title)
            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .padding(10)
            .border(Color.purple, width: 5)
        VStack {
            Button(action: {udpSendString(textToSend: "POWER", address: "192.168.2.101", port: 19001)}, label: {
                    Text("Power ON/OFF").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/).foregroundColor(.gray).padding()})
            HStack {
                Button(action: {udpSendString(textToSend: "VOLUMEUP", address: "192.168.2.101", port: 19001)}, label: {
                    HStack {
                        Image(systemName: "arrowtriangle.up.fill").foregroundColor(.orange).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Text("Up").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(40)
                })
                Button(action: {udpSendString(textToSend: "VOLUMEDOWN", address: "192.168.2.101", port: 19001)}, label: {
                    HStack {
                        Text("Down").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        Image(systemName: "arrowtriangle.down.fill").foregroundColor(.green).font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.yellow)
                    .cornerRadius(40)
                })
            }
        }
        //var adr
        //inet_aton("192.168.2.101", &adr)
//        udpSend(textToSend: "privets_aaa", address: "192.168.2.101", port: 19001)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
