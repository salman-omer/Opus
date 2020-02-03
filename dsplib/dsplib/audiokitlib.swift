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
    
    print("AudioKit test complete")
    
}

