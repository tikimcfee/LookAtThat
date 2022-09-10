//
//  File.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

typealias InstanceIDType = UInt

extension MetalLinkInstancedObject {
    class InstancedConstantsCache: LockingCache<InstanceIDType, InstancedConstants> {
        private var nodeCache = ConcurrentDictionary<UInt, InstancedNodeType>()

        func createNew() -> InstancedConstants {
            return self[InstanceCounter.shared.nextId(.glyph)]
        }
        
        override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
            if store[key] != nil {
                print("Warning - constants for this ID already exist; have you lost track of it?: \(key)")
            }
            return InstancedConstants(instanceID: key)
        }
        
        // Really? Mapping Uint to Int? Hoo boy I'm missing something.
        // Like not having all these constants objects and indexing directly into the buffer...
        // make like way easier. We'll see. As this gets uglier.
        func track(
            node: InstancedNodeType,
            constants: InstancedConstants,
            at index: Int
        ) {
            nodeCache[constants.instanceID] = node
        }
        
        func findNode(for glyphID: InstanceIDType) -> InstancedNodeType? {
            nodeCache[glyphID]
        }
    }
}

// TODO: Make a smarter / safer glyph instance counter
class InstanceCounter {
    enum Kind {
        case glyph
        case grid
    }
    
    // Starting at 10 to avoid conflict with picking texture color
    // start value (1 when .black)
    static let startingGeneratedID: InstanceIDType = 10
    static let shared = InstanceCounter()
    
    static var idMap = [Kind: InstanceIDType]()
    
//    private var currentGeneratedID: InstanceIDType = InstanceCounter.startingGeneratedID
    private init() { }
    
    func nextId(_ kind: Kind) -> InstanceIDType {
        let id = Self.idMap[kind, default: Self.startingGeneratedID]
        Self.idMap[kind] = id + 1
        return id
    }
}
