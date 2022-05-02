//
//  TraceFileIDMap.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/1/22.
//

import Foundation

class TraceLineIDMap {
    class Serialized: Codable {
        var map: [UUID: String] = [:]
    }
    
    let bimap = ConcurrentBiMap<String, UUID>()
    
    subscript(signature: String) -> UUID {
        return bimap[signature] ?? {
            let id = UUID()
            bimap[signature] = id
            return id
        }()
    }
    
    subscript(id: UUID) -> String? {
        return bimap[id]
    }
    
    func encodeValues() throws -> Data {
        let toEncode = Serialized()
        bimap.valuesToKeys.lockAndDo { store in
            store.forEach { (key, value) in
                toEncode.map[key] = value
            }
        }
        let jsonData = try JSONEncoder().encode(toEncode)
        return jsonData
    }
    
    static func decodeFrom(_ data: Data) throws -> TraceLineIDMap {
        let decoded = try JSONDecoder().decode(Serialized.self, from: data)
        
        let newMap = TraceLineIDMap()
        decoded.map.forEach { key, value in
            newMap.bimap[key] = value
        }
        return newMap
    }
}
