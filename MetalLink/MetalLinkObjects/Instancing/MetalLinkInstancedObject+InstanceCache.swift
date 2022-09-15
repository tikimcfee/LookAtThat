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
    
    static var idMap = [Kind: InstanceIDType]()
    
    private init() { }
    
    func nextId(_ kind: Kind) -> InstanceIDType {
        let id = Self.idMap[kind, default: Self.startingGeneratedID]
        Self.idMap[kind] = id + 1
        return id
    }
}
