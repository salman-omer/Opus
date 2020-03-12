//
//  NoteDetector.swift
//  native_app
//
//  Created by Yash Shah on 3/11/20.
//  Copyright © 2020 WEACW. All rights reserved.
//

import Foundation

let threshold: Float = 0.05

func cumulativeDifference(yinBuffer: inout [Float]) {
  yinBuffer[0] = 1.0

  var runningSum: Float = 0.0

  for tau in 1 ..< yinBuffer.count {
    runningSum += yinBuffer[tau]

    if runningSum == 0 {
      yinBuffer[tau] = 1
    } else {
      yinBuffer[tau] *= Float(tau) / runningSum
    }
  }
}

func absoluteThreshold(yinBuffer: [Float], withThreshold threshold: Float) -> Int {
  var tau = 2
  var minTau = 0
  var minVal: Float = 1000.0

  while tau < yinBuffer.count {
    if yinBuffer[tau] < threshold {
      while (tau + 1) < yinBuffer.count && yinBuffer[tau + 1] < yinBuffer[tau] {
        tau += 1
      }
      return tau
    } else {
      if yinBuffer[tau] < minVal {
        minVal = yinBuffer[tau]
        minTau = tau
      }
    }
    tau += 1
  }

  if minTau > 0 {
    return -minTau
  }

  return 0
}

func parabolicInterpolation(yinBuffer: [Float], tau: Int) -> Float {
  guard tau != yinBuffer.count else {
    return Float(tau)
  }

  var betterTau: Float = 0.0

  if tau > 0  && tau < yinBuffer.count - 1 {
    let s0 = yinBuffer[tau - 1]
    let s1 = yinBuffer[tau]
    let s2 = yinBuffer[tau + 1]

    var adjustment = (s2 - s0) / (2.0 * (2.0 * s1 - s2 - s0))

    if abs(adjustment) > 1 {
      adjustment = 0
    }

    betterTau = Float(tau) + adjustment
  } else {
    betterTau = Float(tau)
  }

  return abs(betterTau)
}

func estimateFrequency(sampleRate: Float, buffer: Buffer) throws -> Float {
  var elements = buffer.elements

  cumulativeDifference(yinBuffer: &elements)

  let tau = absoluteThreshold(yinBuffer: elements, withThreshold: threshold)
  var f0: Float

  if tau != 0 {
    let interpolatedTau = parabolicInterpolation(yinBuffer: elements, tau: tau)
    f0 = sampleRate / interpolatedTau
  } else {
    f0 = 0.0
  }

  return f0
}
