//
//  NoteDetector.swift
//  native_app
//
//  Created by Yash Shah on 3/11/20.
//  Copyright © 2020 WEACW. All rights reserved.
//

import Foundation
import Accelerate
import Pitchy

func estimateFrequency(sampleRate: Float, buffer: Buffer) throws -> [Float] {
    let locations: [Int] = try estimateLocation(buffer: buffer)
    var frequencies: [Float] = [];
    for location in locations {
        frequencies.append(Float(location) * sampleRate / (Float(buffer.count) * 2))
    }
    print("num frequencies: \(frequencies.count), data: \(frequencies)")
    return frequencies
}

private let harmonics: Int = 3
private let minIndex = 1
func estimateLocation(buffer: Buffer) throws -> [Int] {
    var spectrum: [Float] = buffer.elements
    let maxIndex = spectrum.count - 1
    var maxHIndex = spectrum.count / harmonics

    if maxIndex < maxHIndex {
      maxHIndex = maxIndex
    }
    
    for j in minIndex...maxHIndex {
      for i in 1...harmonics {
        spectrum[j] *= spectrum[j * i]
      }
    }

    // Find the maximum peak from hps structure
    var maximumPeak: Float = 0.0
    var vdspIndex: vDSP_Length = 0
    vDSP_maxvi(spectrum, 1, &maximumPeak, &vdspIndex, vDSP_Length(spectrum.count))
    
    let lambda: Float = 0.00005 * maximumPeak
    let filteredByLambda: [Float] = vDSP.threshold(spectrum, to: lambda, with: .zeroFill)
    
    let prominenceThreshold: Float = 0.3 * maximumPeak;
    
    var realPitchLocations: [Int] = []
    var uncertainPitchLocations: [Int] = []
    
    for index in 0...maxIndex {
        if(filteredByLambda[index] >= prominenceThreshold) {
            realPitchLocations.append(index)
            
        }
        // Every peak below 27.5 Hz is irrelevant
        else if(filteredByLambda[index] > 0 && Double(index) > (27.5/(buffer.samplingRate/Double((2*buffer.count))))) {
            var foundHarmonicOverflow = false
            for realPitchLocation in realPitchLocations {
                if realPitchLocation % index == 1 {
                    foundHarmonicOverflow = true
                    break
                }
            }
            if(!foundHarmonicOverflow) {
                uncertainPitchLocations.append(index)
            }
        }
    }
    
    for uncertainPitch in uncertainPitchLocations {
        var result: Float = 1.0
        for i in 1...8 {
            if(i * uncertainPitch) < maxIndex {
                result *= spectrum[i * uncertainPitch]
            }
        }
        if(result > 0) {
            realPitchLocations.append(uncertainPitch)
        }
    }
    
    // Lsat Step of thresholding
    let beta1: Float = 0.4
    let beta2: Float = 0.5
    
    var s_real: [Float] = []
    var y_real: [Float] = []
    if !realPitchLocations.isEmpty {
        for realPitchLocation in realPitchLocations {
            y_real.append(buffer.elements[realPitchLocation])
            var result: Float = 0
            for i in 1...9 {
                let index = realPitchLocation * i
                if(index < buffer.count) {
                    result += buffer.elements[index]
                }
            }
            s_real.append(result)
        }
        let s_max: Float = s_real.max()!
        let y_max: Float = y_real.max()!
        
        for uncertainPitchLocation in uncertainPitchLocations {
            var s_current: Float = 0
            for i in 1...9 {
                let index = i*uncertainPitchLocation
                if index < buffer.count {
                    s_current += buffer.elements[index]
                }
            }
            
            let y_current = buffer.elements[uncertainPitchLocation] + (buffer.elements[uncertainPitchLocation-1] ?? 0) + (buffer.elements[uncertainPitchLocation+1] ?? 0)
            
            if (s_current > (beta1 * s_max)) && (y_current > (beta2 * y_max)) {
                var foundHarmonicOverflow = false
                for tmp in uncertainPitchLocations {
                    if tmp % uncertainPitchLocation == 1 {
                        foundHarmonicOverflow = true
                        break
                    }
                }
                if(!foundHarmonicOverflow) {
                    realPitchLocations.append(uncertainPitchLocation)
                }
            }
        }
    }
    
    if(realPitchLocations.count > 10) {
        return [Int(vdspIndex)];
    }
    
    return realPitchLocations;
}
