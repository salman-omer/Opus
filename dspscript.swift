#!/usr/bin/swift

import Foundation
import Accelerate

// following this tutorial https://developer.apple.com/documentation/accelerate/finding_the_component_frequencies_in_a_composite_sine_wave

// The following creates the array, called signal, that contains 10 component sine waves:
let n = vDSP_Length(2048)

let frequencies: [Float] = [1, 5, 25, 30, 75, 100, 300, 500, 512, 1023]

let tau: Float = .pi * 2

let signal: [Float] = (0 ... n).map { index in 
    frequencies.reduce(0) { accumulator, frequency in
        let normalizedIndex = Float(index) / Float(n)
        return accumulator + sin(normalizedIndex * frequency * tau)
    }
}

// signal is an array that represents composite sine waves constructed from the frequencies array.
// Essentially we are going from a list of frequencies to a sinusoid


// Now we need to create initial values for fft setup. According to the docs, this is really
// expensive so we only want to do it once per program run, for example once the app opens

let log2n = vDSP_Length(log2(Float(n)))

guard let fftSetUp = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self) 
    else { 
        fatalError("Can't create FFT Setup") 
    }

