//
//  PersisentThreadTracing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/1/22.
//

import Foundation
import Combine

class PersistentThreadTracer {
    private let idFileTarget: URL
    private let idFileWriter: AppendingStore // TODO: combine reader/writer to consolidate proper inserts
    private var idFileReader: FileUUIDArray
    
    private let sourceMap: TraceLineIDMap
    private let deserializedCache = ConcurrentDictionary<Int, TraceLine>()
    
    private var isBackingCacheDirty: Bool = false
    private var isOneTimeResetFlag: Bool = false
    
    public static var SHOULD_WRITE = false {
        didSet {
            print("\n\n\tPersistentThreadTracer.SHOULD_WRITE = \(SHOULD_WRITE)\n\n")
        }
    }
    
    init(
        idFileTarget: URL,
        sourceMap: TraceLineIDMap
    ) throws {
        self.idFileTarget = idFileTarget
        self.sourceMap = sourceMap
        
        self.idFileWriter = AppendingStore(targetFile: idFileTarget)
        self.idFileReader = try FileUUIDArray.from(fileURL: idFileTarget)
    }
    
    private var shouldRemakeArray: Bool {
        let willReset = isBackingCacheDirty || isOneTimeResetFlag
        isOneTimeResetFlag = false
        return willReset
    }
    
    func onNewTraceLine(_ traceLine: TraceLine) {
        let traceId = sourceMap[traceLine]
        guard Self.SHOULD_WRITE else {
            print("\n\n\t\tWrites disabled!")
            return
        }
        idFileWriter.appendText(traceId.uuidString)
        isBackingCacheDirty = true
    }
    
    func eraseTargetAndReset() {
        idFileWriter.cleanFile()
        isOneTimeResetFlag = true
        evaluateArrayState()
    }
    
    func evaluateArrayState() {
        guard shouldRemakeArray else { return }
        
        do {
            print("Reloading backed array for \(idFileTarget)")
            idFileReader = try FileUUIDArray.from(fileURL: idFileTarget)
            isBackingCacheDirty = false
        } catch {
            print("Error during array reload", error)
        }
    }
}

extension PersistentThreadTracer: RandomAccessCollection {
    var startIndex: Int {
        evaluateArrayState()
        return idFileReader.startIndex
    }
    
    var endIndex: Int {
        evaluateArrayState()
        return idFileReader.endIndex
    }
    
    subscript(position: Int) -> TraceLine {
        if let cached = deserializedCache[position] { return cached }
        evaluateArrayState()
        guard idFileReader.indices.contains(position),
              let id = idFileReader[position],
              let trace = sourceMap[id]
        else {
            print("No trace line found for \(position)")
            return TraceLine.missing
        }
        deserializedCache[position] = trace
        return trace
    }
}
