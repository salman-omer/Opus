//
//  Utils.swift
//  native_app
//
//  Created by Yash Shah on 3/11/20.
//  Copyright © 2020 WEACW. All rights reserved.
//

import Accelerate

extension Array where Element:Comparable {
  static func fromUnsafePointer(_ data: UnsafePointer<Element>, count: Int) -> [Element] {
    let buffer = UnsafeBufferPointer(start: data, count: count)
    return Array(buffer)
  }

  var maxIndex: Int? {
    return self.enumerated().max(by: {$1.element > $0.element})?.offset
  }
}

func sqrtq(_ x: [Float]) -> [Float] {
  var results = [Float](repeating: 0.0, count: x.count)
  vvsqrtf(&results, x, [Int32(x.count)])

  return results
}

func sanitize(location: Int, reserveLocation: Int, elements: [Float]) -> Int {
  return location >= 0 && location < elements.count
    ? location
    : reserveLocation
}
