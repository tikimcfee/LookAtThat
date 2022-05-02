//
//  TraceFileIDMap.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/1/22.
//

import Foundation

class TraceLineIDMap {
    private(set) var persistedBiMap = ConcurrentBiMap<String, UUID>()
    private var memoryMap = ConcurrentBiMap<TraceLine, UUID>()
    
    subscript(line: TraceLine) -> UUID {
        if let memory = memoryMap[line] { return memory }
        
        let lineKey = line.serialize()
        return persistedBiMap[lineKey] ?? {
            let id = UUID()
            persistedBiMap[lineKey] = id
            return id
        }()
    }
    
    subscript(id: UUID) -> TraceLine? {
        if let memory = memoryMap[id] { return memory }
        
        guard let rawTraceLine = persistedBiMap[id],
              let trace = TraceLine.deserialize(traceLine: rawTraceLine)
        else {
            print("Missing trace line for: \(id)")
            return nil
        }
        return trace
    }
}

extension TraceLineIDMap {
    class Serialized: Codable {
        var map: [UUID: String] = [:]
    }
    
    @discardableResult
    func insertRawLine(_ rawTraceLine: String) -> UUID? {
        guard let trace = TraceLine.deserialize(traceLine: rawTraceLine)
            else { return nil }
        return self[trace]
    }
    
    func encodeValues() throws -> Data {
        let toEncode = Serialized()
        persistedBiMap.valuesToKeys.lockAndDo { store in
            store.forEach { (key, value) in
                toEncode.map[key] = value
            }
        }
        let jsonData = try JSONEncoder().encode(toEncode)
        return jsonData
    }
    
    func decodeAndReload(from file: URL) {
        do {
            let newReload = try Self.decodeFrom(file: file)
            reload(from: newReload)
            print("TraceIDMap reloaded: \(file)")
        } catch {
            print("TraceIDMap reload error", error)
        }
    }
    
    private func reload(from source: TraceLineIDMap) {
        self.persistedBiMap = source.persistedBiMap
    }
    
    static func decodeFrom(file: URL) throws -> TraceLineIDMap {
        let mapData = try Data(contentsOf: file)
        guard !mapData.isEmpty else {
            print("File is empty, assuming this is a fresh trace")
            return TraceLineIDMap()
        }
        
        let decoded = try JSONDecoder().decode(Serialized.self, from: mapData)
        let newMap = TraceLineIDMap()
        decoded.map.forEach { key, value in
            newMap.persistedBiMap[key] = value
        }
        return newMap
    }
    
    static func decodeFrom(_ data: Data) throws -> TraceLineIDMap {
        let decoded = try JSONDecoder().decode(Serialized.self, from: data)
        
        let newMap = TraceLineIDMap()
        decoded.map.forEach { key, value in
            newMap.persistedBiMap[key] = value
        }
        return newMap
    }
}
