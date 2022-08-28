//
//  WorldGrid+FocusPosition.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

struct FocusPosition: CustomStringConvertible, Equatable {
    var x: Int {
        didSet { pfocus() }
    }
    var y: Int {
        didSet { pfocus() }
    }
    var z: Int {
        didSet { pfocus() }
    }
    
    func pfocus() {
        //        print("\(x), \(y), \(z)")
    }
    
    var description: String {
        "(\(x), \(y), \(z))"
    }
    
    init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    mutating func left() {
        x = max(0, x - 1)
    }
    
    mutating func right() {
        x = min(x + 1, Int.max - 2)
    }
    
    mutating func up() {
        y = max(0, y - 1)
    }
    
    mutating func down() {
        y = min(y + 1, Int.max - 2)
    }
    
    mutating func forward() {
        z = min(z + 1, Int.max - 2)
    }
    
    mutating func backward() {
        z = max(0, z - 1)
    }
}
