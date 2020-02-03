//
//  audiokitlib.swift
//  dsplib
//
//  Created by Salman on 2/2/20.
//  Copyright © 2020 Capstone. All rights reserved.
//

import Foundation
import AudioKit

func audioKitTest() -> Void{
    let oscillator = AKOscillator()
    let oscillator2 = AKOscillator()
    
    AudioKit.output = AKMixer(oscillator, oscillator2)
    
    do {
        try AudioKit.start()
    } catch {
        AKLog("AudioKit did not start!")
    }
    
    oscillator.amplitude = random(in: 0.5 ... 1)
    oscillator.frequency = random(in: 220 ... 880)
    oscillator.start()
    oscillator2.amplitude = random(in: 0.5 ... 1)
    oscillator2.frequency = random(in: 220 ... 880)
    oscillator2.start()
    
    print("Waves \(Int(oscillator.frequency))Hz & \(Int(oscillator2.frequency))Hz playing")
    sleep(1)
    
    oscillator.stop()
    oscillator2.stop()
    
    print("AudioKit test complete")
    
}

