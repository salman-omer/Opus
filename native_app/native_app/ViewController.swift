//
//  ViewController.swift
//  native_app
//
//  Created by NSWell on 2019/12/19.
//  Copyright © 2019 WEACW. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var timer = Timer()
    
    @IBAction func launchUnityView(_ sender: UIButton) {
        UnityEmbeddedSwift.showUnity()
        
        Timer.scheduledTimer(timeInterval: 2,
                            target: self,
                            selector: #selector(updateCounting),
                            userInfo: nil,
                            repeats: true)
        
        self.navigationController?.pushViewController(UnityEmbeddedSwift.getUnityRootview(), animated: true)
        
    }
    
    @objc func updateCounting(){
        print("sending message")
        UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_processFrequencyData", message: "Hello this is the message")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

