//
//  ViewController.swift
//  denon_remote_i6
//
//  Created by ealefad on 2021-05-03.
//  Copyright © 2021 ealefad. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView(frame: self.view.bounds)
            imageView.image = UIImage(named: "background_eagle")//if its in images.xcassets
            self.view.addSubview(imageView)
        
        var denonState = MEM_STATE_T()
        var volumeString = "unknown"
        var dimmerImage: Int8 = 0
        var imageIndex: Int8 = 0
        var dimmerButtonSize: CGFloat = 30
        var muteSpeakerImg = "speaker"
        
        // Do any additional setup after loading the view, typically from a nib.
        let buttonX = 20
        let buttonY = 100
        let buttonWidth = 100
        let buttonHeight = 50
        let rowX_offset = 170
        let rowY_offset = 200
        
        let buttonON = UIButton(type: .roundedRect)
        buttonON.setTitle("ON", for: .normal)
        buttonON.tintColor = .systemGreen
        buttonON.backgroundColor = .gray
        buttonON.addTarget(self, action: #selector(button_ON_Clicked), for: .touchUpInside)
        buttonON.frame = CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
        buttonON.layer.cornerRadius = buttonON.frame.height * 0.50
        self.view.addSubview(buttonON)
        
        let buttonOFF = UIButton(type: .system)
        buttonOFF.setTitle("OFF", for: .normal)
        buttonOFF.tintColor = .systemGreen
        buttonOFF.backgroundColor = .gray
        buttonOFF.addTarget(self, action: #selector(button_OFF_Clicked), for: .touchUpInside)
        buttonOFF.frame = CGRect(x: buttonX + rowX_offset, y: buttonY, width: buttonWidth, height: buttonHeight)
        buttonOFF.layer.cornerRadius = buttonOFF.frame.height * 0.50
        self.view.addSubview(buttonOFF)
        
        let button1 = UIButton(type: .system)
        button1.setTitle("Vol UP +", for: .normal)
        button1.tintColor = .black
        button1.backgroundColor = .orange
        button1.addTarget(self, action: #selector(button1Clicked), for: .touchUpInside)
        button1.frame = CGRect(x: buttonX + rowX_offset, y: buttonY + rowY_offset, width: buttonWidth, height: buttonHeight)
        button1.layer.cornerRadius = button1.frame.height * 0.50
        self.view.addSubview(button1)
        
        let button2 = UIButton(type: .system)
        button2.setTitle("Vol DOWN -", for: .normal)
        button2.tintColor = .black
        button2.backgroundColor = .green
        button2.addTarget(self, action: #selector(button2Clicked), for: .touchUpInside)
        button2.frame = CGRect(x: buttonX, y: buttonY + rowY_offset, width: buttonWidth, height: buttonHeight)
        button2.layer.cornerRadius = button2.frame.height * 0.50
        self.view.addSubview(button2)
        
        let buttonMUTE = UIButton(type: .system)
        buttonMUTE.setTitle("MUTE", for: .normal)
        buttonMUTE.tintColor = .blue
        buttonMUTE.backgroundColor = .yellow
        buttonMUTE.addTarget(self, action: #selector(button_MUTE_Clicked), for: .touchUpInside)
        buttonMUTE.frame = CGRect(x: 120, y: buttonY + rowY_offset + 150, width: buttonWidth, height: buttonHeight)
        buttonMUTE.layer.cornerRadius = buttonMUTE.frame.height * 0.50
        self.view.addSubview(buttonMUTE)
        
    }
    
    @objc func button_ON_Clicked(sender : UIButton){
        //udpSendString(textToSend: "CMD04PWRON", address: "192.168.2.101", port: 19001)
        _ = sendCommand(cmd: "CMD04PWRON", rxTO: 1)
    }
    
    @objc func button_OFF_Clicked(sender : UIButton){
        //udpSendString(textToSend: "CMD05PWROFF", address: "192.168.2.101", port: 19001)
        _ = sendCommand(cmd: "CMD05PWROFF", rxTO: 1)
    }
    
    @objc func button1Clicked(sender : UIButton){
//        let alert = UIAlertController(title: "Clicked", message: "You have clicked on the button", preferredStyle: .alert)
//
//        self.present(alert, animated: true, completion: nil)
        //udpSendString(textToSend: "CMD02VOLUMEUP__", address: "192.168.2.101", port: 19001)
        _ = sendCommand(cmd: "CMD02VOLUMEUP__", rxTO: 1)
    }
    
    @objc func button2Clicked(sender : UIButton){
        //udpSendString(textToSend: "CMD03VOLUMEDOWN", address: "192.168.2.101", port: 19001)
        _ = sendCommand(cmd: "CMD03VOLUMEDOWN", rxTO: 1)
    }
    
    @objc func button_MUTE_Clicked(sender : UIButton){
        //udpSendString(textToSend: "CMD06MUTE", address: "192.168.2.101", port: 19001)
        _ = sendCommand(cmd: "CMD06MUTE", rxTO: 1)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

