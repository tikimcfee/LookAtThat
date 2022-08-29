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
        private var indexCache = ConcurrentDictionary<UInt, Int>()
        
        func createNew() -> InstancedConstants {
            return self[InstanceCounter.shared.nextId()]
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
        func track(constant: InstancedConstants, at index: Int) {
            indexCache[constant.instanceID] = index
        }
        
        func findConstantIndex(for instanceID: InstanceIDType) -> Int? {
            indexCache[instanceID]
        }
    }
}

// TODO: Make a smarter / safer glyph instance counter
private class InstanceCounter {
    static let shared = InstanceCounter()
    private init() { }
    
    // Starting at 10 to avoid conflict with picking texture color
    // start value (1 when .black)
    private var currentGeneratedID: InstanceIDType = 10
    func nextId() -> InstanceIDType {
        let id = currentGeneratedID
        //        print("Gen: \(id)")
        currentGeneratedID += 1
        return id
    }
}
