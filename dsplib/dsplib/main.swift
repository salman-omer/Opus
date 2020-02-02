#!/usr/bin/swift

import Accelerate
import Foundation

// following this tutorial https://developer.apple.com/documentation/accelerate/finding_the_component_frequencies_in_a_composite_sine_wave

// The following creates the array, called signal, that contains 10 component
// sine waves:
let n = vDSP_Length(2048)

let frequencies: [Float] = [1, 5, 25, 30, 75, 100, 300, 500, 512, 1023]

let tau: Float = .pi * 2

let signal: [Float] = (0 ... n).map { index in
    frequencies.reduce(0) { accumulator, frequency in
        let normalizedIndex = Float(index) / Float(n)
        return accumulator + sin(normalizedIndex * frequency * tau)
    }
}

// signal is an array that represents composite sine waves constructed from the
// frequencies array. Essentially we are going from a list of frequencies to a
// sinusoid

// Now we need to create initial values for fft setup. According to the docs,
// this is really expensive so we only want to do it once per program run, for
// example once the app opens

let log2n = vDSP_Length(log2(Float(n)))

guard let fftSetUp = vDSP.FFT(log2n: log2n, radix: .radix2, ofType: DSPSplitComplex.self)
else {
    fatalError("Can't create FFT Setup")
}

// Note, this is a small sized FFT, so this setup object can be easily used for
// other small ffts. But for large FFTS, the setup object may cause bad
// performance when applied to smaller problems so it is important to watch for
// that.

// Create real and im part of fft for input and output

let halfN = Int(n / 2)

// below is some really cool Swift magic. It creates arrays of size halfN of all
// zeros.
var forwardInputReal = [Float](repeating: 0,
                               count: halfN)
var forwardInputImag = [Float](repeating: 0,
                               count: halfN)
var forwardOutputReal = [Float](repeating: 0,
                                count: halfN)
var forwardOutputImag = [Float](repeating: 0,
                                count: halfN)

// (Salman)- someone explain this to me please! "Because each complex value
// stores two real values, the length of teach array is half that of signal."
// Maybe has something to do with: "The conversion stores the even values in
// signal as the real components in forwardInput, and the odd values in signal
// as the imaginary components in forwardInput."

/*
 To perform the forward FFT:

 1.Create a DSPSplitComplex structure to store signal represented as complex
 numbers.

 2.Use convert(interleavedComplexVector:toSplitComplexVector:) to convert the
 real values in signal to complex numbers. The conversion stores the even values
 in signal as the real components in forwardInput, and the odd values in signal
 as the imaginary components in forwardInput.

 3.Create a DSPSplitComplex structure with pointers to forwardOutputReal and
 forwardOutputImag to receive the FFT result.

 4.Perform the forward FFT.
 */

// (Salman) - It seems that we use withUnsafeMutableBufferPointer and
// array.baseAddress to make this super robust, but tbh I don't fully understand
// when and why we would use it otherwise.
// https://stackoverflow.com/questions/34259513/swift-array-memory-address-changes-when-referring-to-the-same-variable

forwardInputReal.withUnsafeMutableBufferPointer { forwardInputRealPtr in
    forwardInputImag.withUnsafeMutableBufferPointer { forwardInputImagPtr in
        forwardOutputReal.withUnsafeMutableBufferPointer { forwardOutputRealPtr in
            forwardOutputImag.withUnsafeMutableBufferPointer { forwardOutputImagPtr in

                // 1: Create a `DSPSplitComplex` to contain the signal.
                var forwardInput = DSPSplitComplex(realp: forwardInputRealPtr.baseAddress!,
                                                   imagp: forwardInputImagPtr.baseAddress!)

                // 2: Convert the real values in `signal` to complex numbers.
                signal.withUnsafeBytes {
                    vDSP.convert(interleavedComplexVector: [DSPComplex]($0.bindMemory(to: DSPComplex.self)),
                                 toSplitComplexVector: &forwardInput)
                }

                // 3: Create a `DSPSplitComplex` to receive the FFT result.
                var forwardOutput = DSPSplitComplex(realp: forwardOutputRealPtr.baseAddress!,
                                                    imagp: forwardOutputImagPtr.baseAddress!)

                // 4: Perform the forward FFT.
                fftSetUp.forward(input: forwardInput,
                                 output: &forwardOutput)
            }
        }
    }
}

// The forwardOutputImag (or the Nyquist components of the foward FFT) contain
// the frequencies of the input!
let componentFrequencies = forwardOutputImag.enumerated().filter {
    $0.element < -1
}.map {
    $0.offset
}

// Prints "[1, 5, 25, 30, 75, 100, 300, 500, 512, 1023]"
print(componentFrequencies)

// We could also recreate the signal - check the guide if that is something you
// want to do (probably don't for this project)

