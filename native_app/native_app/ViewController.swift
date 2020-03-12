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
                let pitch = try Pitch(frequency: Double(frequency))
                
                print("Note: \(pitch.offsets.closest.note.string), Frequency: \(frequency)")
            } catch {}
        }
    }
    
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
        sampler = AudioSampler(onReceived: self.onAudioSampleReceived)
        sampler?.start()
    }

}
