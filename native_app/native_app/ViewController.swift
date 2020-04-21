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
    private var POWER_THRESHOLD: Float = -35
    
    // preivousNoteSet is the set of notes for the previous block of samples
    var previousNoteSet: Set<String> = Set.init()
    
    // runningSet is the set of notes for the current block of samples
    var runningSet: Set<String> = Set.init()
    
    // currentlyPlayingNotes is the set of notes that the game sees as playing
    var currentlyPlayingNotes: Set<String> = Set.init()
    var evenCount: Bool = false
    
    // This function runs ten times a second and handles our samples, deciding when to send information to unity or not
    func onAudioSampleReceived(buffer: Buffer, time: AVAudioTime, powerLevel: Float) {
        do {
            var frequencies: [Float] = []
            if(powerLevel > POWER_THRESHOLD) {
                    frequencies = try estimateFrequency(sampleRate: Float(time.sampleRate), buffer: buffer)
                
                    // send current sound power level to unity
                    UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_currentPowerLevel", message: NSString(format: "%.2f", powerLevel) as String)
            }
            
            for frequency in frequencies {
                let note = try Note(frequency: Double(frequency))
                runningSet.insert(note.string)
            }
            
            // if any of the curr running frequencies are new, send a noteIsStartedMessage to unity with them
            var noteIsStartedMessage: String?
            for note in runningSet {
                // Construct start note message
                if !currentlyPlayingNotes.contains(note) {
                    currentlyPlayingNotes.insert(note)
                    
                    if noteIsStartedMessage != nil {
                        noteIsStartedMessage!.append(" " + note)
                    } else {
                        noteIsStartedMessage = note
                    }
                }
            }
            
            // Send noteIsStartedMessage to unity if its not empty
            if let startNotesMessage = noteIsStartedMessage {
                UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_startNotes", message: startNotesMessage)
            }
            
            
            if(evenCount){
                // Construct noteIsEndedMessage
                var noteIsEndedMessage: String?
                for note in previousNoteSet {
                    // Construct start note message
                    if !runningSet.contains(note) {
                        currentlyPlayingNotes.remove(note)
                        
                        if noteIsEndedMessage != nil {
                            noteIsEndedMessage!.append(" " + note)
                        } else {
                            noteIsEndedMessage = note
                        }
                    }
                }
                
                // send NoteIsEndedMessage
                if let endNotesMessage = noteIsEndedMessage {
                    UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_endNotes", message: endNotesMessage)
                }
                
                // Set previous set to be the currRunningSet
                previousNoteSet.removeAll()
                for note in runningSet {
                    previousNoteSet.insert(note)
                }
                
                // Clear currRunning set at the end of every Even
                runningSet.removeAll(keepingCapacity: true)
            }
            
            
            
        } catch {}
        
        evenCount = !evenCount
    }
    
    
//    func onAudioSampleReceived(buffer: Buffer, time: AVAudioTime, meetsPowerThreshold: Bool) {
//            if(meetsPowerThreshold) {
//                do {
//                    let frequency = try estimateFrequency(sampleRate: Float(time.sampleRate), buffer: buffer)
//                    let note = try Note(frequency: Double(frequency))
//
//                    // If we get a new note, we want to send that information, as well as indicate the end of an
//                    // old note if it has not already been indicated
//                    if (note.string != previousNote) {
//                        let startMessage = "StartNote: \(note.string) Time: \(printDate())"
//                        UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_startNote", message: startMessage)
//
//                        if(previousNote != nil){
//                            let endMessage = "EndNote: \(previousNote!) Time: \(printDate())"
//                            UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_endNote", message: endMessage)
//                        }
//                        previousNote = note.string
//                    }
//
//                } catch {}
//
//            }
//            else if(previousNote != nil){
//                let endMessage = "EndNote: \(previousNote!) Time: \(printDate())"
//                UnityEmbeddedSwift.sendUnityMessage("level_controller", methodName: "_endNote", message: endMessage)
//                previousNote = nil
//            }
//        }
    
    func printDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        return formatter.string(from: date)
    }
    
    func launchUnityView() {
        UnityEmbeddedSwift.showUnity()

        CATransaction.begin()
        self.navigationController?.pushViewController(UnityEmbeddedSwift.getUnityRootview(), animated: true)
        CATransaction.setCompletionBlock {
            self.sampler?.start()
            print("DEBUG: Sampler started upon game open");
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true;

        // Do any additional setup after loading the view.
        sampler = AudioSampler(onReceived: self.onAudioSampleReceived)
        // For some reason we need to call the sampler start twice? Don't remove this
        // one or the one in launchUnityView()
        self.sampler?.start()
        print("DEBUG: Sampler started upon app open");
        launchUnityView();
    }

}
