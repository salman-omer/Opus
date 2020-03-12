//
//  Utils.swift
//  native_app
//
//  Created by Yash Shah on 3/11/20.
//  Copyright © 2020 WEACW. All rights reserved.
//

extension Array where Element:Comparable {
  static func fromUnsafePointer(_ data: UnsafePointer<Element>, count: Int) -> [Element] {
    let buffer = UnsafeBufferPointer(start: data, count: count)
    return Array(buffer)
  }

  var maxIndex: Int? {
    return self.enumerated().max(by: {$1.element > $0.element})?.offset
  }
}
