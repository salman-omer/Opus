//
//  ViewController.swift
//  native_app
//
//  Created by NSWell on 2019/12/19.
//  Copyright © 2019 WEACW. All rights reserved.
//

import UIKit
import AVFoundation
import Pitchy

class ViewController: UIViewController {

    var timer = Timer()
    var sampler: AudioSampler?
    
    func onAudioSampleReceived(buffer: Buffer, time: AVAudioTime, meetsPowerThreshold: Bool) {
        if(meetsPowerThreshold) {
            do {
                let frequency = try estimateFrequency(sampleRate: Float(time.sampleRate), buffer: buffer)
                let note = try Note(frequency: Double(frequency))
                let message = "Note: \(note.string) LowerNote: \(try note.lower().string) HigherNote: \(try note.higher().string)"
                
                UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_processFrequencyData", message: message)
            } catch {}
        }
    }
    
    @objc func updateCounting(){
        print("sending message")
        UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_processFrequencyData", message: "Hello this is the message")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true;
        
        
        // Do any additional setup after loading the view.
        sampler = AudioSampler(onReceived: self.onAudioSampleReceived)
        
        UnityEmbeddedSwift.showUnity()
        
        CATransaction.begin()
        // Below is some transition code that I tried to use but it didnt work for some reason
//        let transition:CATransition = CATransition()
//        transition.duration = 0.5
//        transition.type = CATransitionType.fade
//        self.navigationController?.view.layer.add(transition, forKey: nil)
        self.navigationController?.pushViewController(UnityEmbeddedSwift.getUnityRootview(), animated: true)
        
        CATransaction.setCompletionBlock {
            self.sampler?.start()
        }
    }

}
