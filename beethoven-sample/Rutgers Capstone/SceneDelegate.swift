//
//  SceneDelegate.swift
//  Rutgers Capstone
//
//  Created by Yash Shah on 2/18/20.
//  Copyright © 2020 Yash Shah. All rights reserved.
//

import UIKit
import SwiftUI
import AVFoundation
import Accelerate

struct Buffer {
  var elements: [Float]
  var realElements: [Float]?
  var imagElements: [Float]?

  var count: Int {
    return elements.count
  }

  // MARK: - Initialization
  init(elements: [Float], realElements: [Float]? = nil, imagElements: [Float]? = nil) {
    self.elements = elements
    self.realElements = realElements
    self.imagElements = imagElements
  }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    private let bufferSize: AVAudioFrameCount = 2048
    private var audioChannel: AVCaptureAudioChannel?
    private let captureSession = AVCaptureSession()
    private var audioEngine: AVAudioEngine?
    private let session = AVAudioSession.sharedInstance()
    private let bus = 0
    
    var peakLevel: Float? {
      return audioChannel?.peakHoldLevel
    }

    var averageLevel: Float? {
      return audioChannel?.averagePowerLevel
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
        
//        do {
//          let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
//          let audioCaptureInput = try AVCaptureDeviceInput(device: audioDevice!)
//
//          captureSession.addInput(audioCaptureInput)
//
//          let audioOutput = AVCaptureAudioDataOutput()
//          captureSession.addOutput(audioOutput)
//
//          let connection = audioOutput.connections[0]
//          audioChannel = connection.audioChannels[0]
//        } catch {}
        
        audioEngine = AVAudioEngine()

        guard let inputNode = audioEngine?.inputNode else {
            print("Input Node Missing")
            return
        }
        
        let format = inputNode.outputFormat(forBus: bus)
        
        inputNode.installTap(onBus: bus, bufferSize: 2048, format: format) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime) in
            do {
                let transformedBuffer = try self.transform(buffer: buffer)
                let frequency = try self.estimateFrequency(sampleRate: Float(time.sampleRate), buffer: transformedBuffer)
                print("\(Double(frequency))")
            } catch {}
        }
        
        do {
            try audioEngine?.start()
            captureSession.startRunning()
        } catch {
            print("error")
        }
    }
    
    let threshold: Float = 0.05

    func estimateFrequency(sampleRate: Float, buffer: Buffer) throws -> Float {
      var elements = buffer.elements

      YINUtil.cumulativeDifference(yinBuffer: &elements)

      let tau = YINUtil.absoluteThreshold(yinBuffer: elements, withThreshold: threshold)
      var f0: Float

      if tau != 0 {
        let interpolatedTau = YINUtil.parabolicInterpolation(yinBuffer: elements, tau: tau)
        f0 = sampleRate / interpolatedTau
      } else {
        f0 = 0.0
      }

      return f0
    }
    
    func transform(buffer: AVAudioPCMBuffer) throws -> Buffer {
      let frameCount = buffer.frameLength
      let log2n = UInt(round(log2(Double(frameCount))))
      let bufferSizePOT = Int(1 << log2n)
      let inputCount = bufferSizePOT / 2
      let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))

      var realp = [Float](repeating: 0, count: inputCount)
      var imagp = [Float](repeating: 0, count: inputCount)
      var output = DSPSplitComplex(realp: &realp, imagp: &imagp)

      let windowSize = bufferSizePOT
      var transferBuffer = [Float](repeating: 0, count: windowSize)
      var window = [Float](repeating: 0, count: windowSize)

      vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
      vDSP_vmul((buffer.floatChannelData?.pointee)!, 1, window,
        1, &transferBuffer, 1, vDSP_Length(windowSize))

      let temp = UnsafePointer<Float>(transferBuffer)

      temp.withMemoryRebound(to: DSPComplex.self, capacity: transferBuffer.count) { (typeConvertedTransferBuffer) -> Void in
          vDSP_ctoz(typeConvertedTransferBuffer, 2, &output, 1, vDSP_Length(inputCount))
      }

      vDSP_fft_zrip(fftSetup!, &output, 1, log2n, FFTDirection(FFT_FORWARD))

      var magnitudes = [Float](repeating: 0.0, count: inputCount)
      vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(inputCount))

      var normalizedMagnitudes = [Float](repeating: 0.0, count: inputCount)
      vDSP_vsmul(sqrtq(magnitudes), 1, [2.0 / Float(inputCount)],
        &normalizedMagnitudes, 1, vDSP_Length(inputCount))

      let buffer = Buffer(elements: normalizedMagnitudes)

      vDSP_destroy_fftsetup(fftSetup)

      return buffer
    }
    
    func sqrtq(_ x: [Float]) -> [Float] {
      var results = [Float](repeating: 0.0, count: x.count)
      vvsqrtf(&results, x, [Int32(x.count)])

      return results
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        guard audioEngine != nil else {
          return
        }

        audioEngine?.stop()
        audioEngine?.reset()
        audioEngine = nil
        captureSession.stopRunning()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

