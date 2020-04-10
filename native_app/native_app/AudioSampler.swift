//
//  AudioSampler.swift
//  native_app
//
//  Created by Yash Shah on 3/11/20.
//  Copyright © 2020 WEACW. All rights reserved.
//

import AVFoundation
import Accelerate

// MARK: Buffer
struct Buffer {
  var elements: [Float]
  var realElements: [Float]?
  var imagElements: [Float]?

  var count: Int {
    return elements.count
  }

  init(elements: [Float], realElements: [Float]? = nil, imagElements: [Float]? = nil) {
    self.elements = elements
    self.realElements = realElements
    self.imagElements = imagElements
  }
}

enum AudioSamplerErrors: Error {
  case floatChannelDataIsNil
}

// MARK: Audio Sampler
class AudioSampler {
    
    // Callback function used to notify the main view when we've received audio samples
    // and allow it to begin processing the data. It provides three points of data:
    // (1) Transformed Audio Buffer
    // (2) Time the sample was taken at
    // (3) Whether or not the sample met the power level threshold
    var callback : (Buffer, AVAudioTime, Bool) -> Void
    
    // MARK: - Buffer Size
    // The following value can be adjusted to increase or decrease audio frame count.
    private let bufferSize: AVAudioFrameCount = 4410
    private var samplingWindow: [Float] = []
    private var samplingIndex = 0
    
    private var levelThreshold : Float?
    private var audioChannel: AVCaptureAudioChannel?
    private let captureSession = AVCaptureSession()
    private var audioEngine: AVAudioEngine?
    private let session = AVAudioSession.sharedInstance()
    private let bus = 0
    
    // MARK: - Initializer
    required init(onReceived: ((Buffer, AVAudioTime, Bool) -> Void)!) {
        self.callback = onReceived
    }
    
    // MARK: - Start Listening
    func start() {
        audioEngine = AVAudioEngine()
        
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord)
            try session.setPreferredSampleRate(44100)
            try session.setActive(true)
        } catch {}

        guard let inputNode = audioEngine?.inputNode else {
            print("Input Node Missing")
            return
        }
        
        let format = inputNode.inputFormat(forBus: bus)
        
        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: format) {
            [weak self] (buffer: AVAudioPCMBuffer!, time: AVAudioTime) in
            
            guard let strongSelf = self else {
                return
            }
            
            do {
                guard let pointer = buffer.floatChannelData else {
                    throw AudioSamplerErrors.floatChannelDataIsNil
                }
                
                if(strongSelf.samplingIndex == 16384) {
                    strongSelf.samplingWindow = strongSelf.samplingWindow[Int(buffer.frameLength)...] + Array.fromUnsafePointer(pointer.pointee, count: Int(buffer.frameLength))
                    // Check average decibel level of our sampling window
                    strongSelf.audioMetering(samples: strongSelf.samplingWindow, frameCount: strongSelf.samplingWindow.count, channelCount: buffer.format.channelCount)
                    // Generate Buffer struct from data and send to sample received delegate
                    let transformedBuffer = try strongSelf.transform(elements: strongSelf.samplingWindow)
//                    print("bufferLength: \(transformedBuffer.elements.count), time: \(time.sampleTime), powerLevel: \(strongSelf.averagePowerForChannel0)")
                    strongSelf.callback(transformedBuffer, time, strongSelf.averagePowerForChannel0 > strongSelf.POWER_THRESHOLD)
                } else {
                    let remaining = 16384 - strongSelf.samplingWindow.count
//                    print("remaining: \(remaining), sampleCount: \(strongSelf.samplingWindow.count), samplingIndex: \(strongSelf.samplingIndex)")
                    if(remaining < buffer.frameLength) {
                        let sliceFrom: Int = Int(buffer.frameLength) - remaining
                        strongSelf.samplingWindow = strongSelf.samplingWindow[sliceFrom...] + Array.fromUnsafePointer(pointer.pointee, count: Int(buffer.frameLength))
                        strongSelf.samplingIndex = 16384
                    } else {
                        strongSelf.samplingWindow = strongSelf.samplingWindow + Array.fromUnsafePointer(pointer.pointee, count: Int(buffer.frameLength))
                        //                    print("samplingIndex: \(strongSelf.samplingIndex), windowCount: \(strongSelf.samplingWindow.count)")
                        strongSelf.samplingIndex += Int(buffer.frameLength)
                    }
                    
                }
            } catch {}
        }
        
        do {
            try audioEngine?.start()
            captureSession.startRunning()
        } catch {
            print("error")
        }
    }
    
    // MARK: - Stop Listening
    func stop() {
      guard audioEngine != nil else {
        return
      }

      audioEngine?.stop()
      audioEngine?.reset()
      audioEngine = nil
      captureSession.stopRunning()
    }
    
    // MARK: - Audio Buffer Transformer
    func transform(elements: [Float]) throws -> Buffer {
        let buffer = Buffer(elements: elements)
        let diffElements = difference(buffer: buffer.elements)
        return Buffer(elements: diffElements)
    }
    
    func difference(buffer: [Float]) -> [Float] {
      let bufferHalfCount = buffer.count / 2
      var resultBuffer = [Float](repeating:0.0, count:bufferHalfCount)
      var tempBuffer = [Float](repeating:0.0, count:bufferHalfCount)
      var tempBufferSq = [Float](repeating:0.0, count:bufferHalfCount)
      let len = vDSP_Length(bufferHalfCount)
      var vSum: Float = 0.0

      for tau in 0 ..< bufferHalfCount {
        let bufferTau = UnsafePointer<Float>(buffer).advanced(by: tau)
        // do a diff of buffer with itself at tau offset
        vDSP_vsub(buffer, 1, bufferTau, 1, &tempBuffer, 1, len)
        // square each value of the diff vector
        vDSP_vsq(tempBuffer, 1, &tempBufferSq, 1, len)
        // sum the squared values into vSum
        vDSP_sve(tempBufferSq, 1, &vSum, len)
        // store that in the result buffer
        resultBuffer[tau] = vSum
      }

      return resultBuffer
    }
    
    // MARK: - Audio Level Metering
    // This section deals with the logic around identifying which set of samples includes
    // data that is not simply background noise
    private var averagePowerForChannel0: Float = 0
    private var averagePowerForChannel1: Float = 0
    let LEVEL_LOWPASS_TRIG:Float32 = 0.30
    
    // MARK: - Audio Level Threshold
    // The following value can be adjusted to allow for more or less noise.
    private var POWER_THRESHOLD: Float = -35
    
    var peakLevel: Float? {
      return audioChannel?.peakHoldLevel
    }

    var averageLevel: Float? {
      return audioChannel?.averagePowerLevel
    }
    
    func audioMetering(samples: [Float], frameCount: Int, channelCount: AVAudioChannelCount) {
        if channelCount > 0 {
            var avgValue:Float32 = 0
            vDSP_meamgv(samples, 1, &avgValue, UInt(frameCount))
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            self.averagePowerForChannel0 = (self.LEVEL_LOWPASS_TRIG*v) + ((1-self.LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel0)
            self.averagePowerForChannel1 = self.averagePowerForChannel0
        }

        if channelCount > 1 {
            var avgValue:Float32 = 0
            vDSP_meamgv(samples, 1, &avgValue, UInt(frameCount))
            var v:Float = -100
            if avgValue != 0 {
                v = 20.0 * log10f(avgValue)
            }
            self.averagePowerForChannel1 = (self.LEVEL_LOWPASS_TRIG*v) + ((1-self.LEVEL_LOWPASS_TRIG)*self.averagePowerForChannel1)
        }
    }
    
}
