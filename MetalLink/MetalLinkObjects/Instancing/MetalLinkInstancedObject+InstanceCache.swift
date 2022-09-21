//
//  File.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

// TODO: Make a smarter / safer glyph instance counter
class InstanceCounter {
    enum Kind {
        case glyph
        case grid
        case generic
    }
    
    // Starting at 10 to avoid conflict with picking texture color
    // start value (1 when .black)
    static let startingGeneratedID: InstanceIDType = 10
    static let shared = InstanceCounter()
    
    private let gridLock = DispatchSemaphore(value: 1)
    private lazy var gridId = Self.startingGeneratedID
    
    private let glyphLock = DispatchSemaphore(value: 1)
    private lazy var glyphId = Self.startingGeneratedID
    
    private init() { }
    
    func nextGridId() -> InstanceIDType {
        gridLock.wait()
        let id = gridId
        gridId += 1
        gridLock.signal()
        return id
    }
    
    func nextGlyphId() -> InstanceIDType {
        glyphLock.wait()
        let id = glyphId
        glyphId += 1
        glyphLock.signal()
        return id
    }
}
