#!/usr/bin/swift

import Foundation

audioKitSetup()

let result: [Double] = getAudioSample(iterations: 10000)
print(result)
