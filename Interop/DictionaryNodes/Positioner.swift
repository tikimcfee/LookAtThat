//
//  Positioner.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation

actor Positioner {
    var column: Int = 0
    var row: Int = 0
    var depth: Int = 0
    
    var sideLength: Int
    
    init(sideLength: Int) {
        self.sideLength = sideLength
    }
    
    private func nextDepth() -> Int {
        let val = depth
        return val
    }
    
    private func nextColumn() -> Int {
        let val = column
//        if val >= sideLength / 4 {
//            column = 0
//            depth += 1
//        }
        return val
    }
    
    private func nextRow() -> Int {
        let val = row
        if val >= sideLength {
            row = 0
            column += 1
        }
        row += 1
        return val
    }
    
    func nextPos() -> (Int, Int, Int) {
        (nextRow(), nextColumn(), nextDepth())
    }
}
