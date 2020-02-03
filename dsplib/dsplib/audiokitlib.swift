//
//  audiokitlib.swift
//  dsplib
//
//  Created by Salman on 2/2/20.
//  Copyright © 2020 Capstone. All rights reserved.
//

import Foundation
import AudioKit
import AVFoundation

var mic: AKMicrophone!
var tracker: AKFrequencyTracker!
var silence: AKBooster!

func audioKitHelloWorld() -> Void{
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

func audioKitSetup() -> Bool {
    AKSettings.audioInputEnabled = true
    mic = AKMicrophone()
    tracker = AKFrequencyTracker(mic)
    silence = AKBooster(tracker, gain: 0)
    AudioKit.output = silence
    
    AVCaptureDevice.requestAccess(for: AVMediaType.audio) { (completed) in
        print(completed)
    }
    
    do {
        if let inputs = AudioKit.inputDevices {
            try AudioKit.setInputDevice(inputs[0])
            try mic.setDevice(inputs[0])
        }
        try AudioKit.start()
        mic.start()
        tracker.start()
        print("Audiokit setup complete")
    } catch {
        AKLog("AudioKit did not start!")
        return false
    }
    return true
}


func getAudioSample(iterations: Int) -> [Double]{
    var waveform: [Double] = []
    
    while(true){
        usleep(1000000)
        let currAmplitude = tracker.amplitude
        print(tracker.frequency)
        if currAmplitude > 0.001 {
            print(currAmplitude)
            waveform.append(tracker.amplitude)
        }
    }
    
    return waveform
}

