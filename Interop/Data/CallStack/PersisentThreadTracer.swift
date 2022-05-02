//
//  PersisentThreadTracing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/1/22.
//

import Foundation

class PersistentThreadTracer {
    private let idFileTarget: URL
    private let idFileWriter: AppendingStore // TODO: combine reader/writer to consolidate proper inserts
    private var idFileReader: FileUUIDArray
    
    private let sourceMap: TraceLineIDMap
    private let deserializedCache = ConcurrentDictionary<Int, TraceLine>()
    
    private var isBackingCacheDirty: Bool = false
    private var isOneTimeResetFlag: Bool = false
    private var shouldRemakeArray: Bool {
        let willReset = isBackingCacheDirty || isOneTimeResetFlag
        isOneTimeResetFlag = false
        return willReset
    }
    
    internal init(
        idFileTarget: URL,
        sourceMap: TraceLineIDMap // share json map to avoid repeated function writes
    ) throws {
        self.idFileTarget = idFileTarget
        self.sourceMap = sourceMap
        
        self.idFileWriter = AppendingStore(targetFile: idFileTarget)
        self.idFileReader = try FileUUIDArray.from(fileURL: idFileTarget)
    }
    
    static var AllWritesEnabled = false
    
    func onNewTraceLine(_ traceLine: TraceLine) {
        let traceId = sourceMap[traceLine]
        
        guard Self.AllWritesEnabled else { return }
        isBackingCacheDirty = true
        idFileWriter.appendText(traceId.uuidString)
    }
    
    func eraseTargetAndReset() throws {
        idFileWriter.cleanFile()
        idFileReader = try FileUUIDArray.from(fileURL: idFileTarget)
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

// MARK: Thread->Tracer group

typealias StorageCollectionType = NSMutableArray
typealias StorageCollectionDowncast = NSArray
typealias StorageElement = TraceLine

class PersistentThreadGroup {
    private var failedThreads = ConcurrentArray<Thread>()
    private let fileIOStorage = ConcurrentDictionary<Thread, PersistentThreadTracer>()
    var sharedSignatureMap: TraceLineIDMap
    var lastKey: String?
    
    init() {
        do {
            let defaultMapFile = AppFiles.getDefaultTraceMapFile()
            self.sharedSignatureMap = try TraceLineIDMap.decodeFrom(file: defaultMapFile)
        } catch {
            print("Unable to load persisted trace IDs, starting with empty store", error)
            self.sharedSignatureMap = TraceLineIDMap()
        }
    }
    
    // TODO: load from file set, currently lazy loads from thread name if loaded from file
    func tracer(for thread: Thread) -> PersistentThreadTracer? {
        guard !failedThreads.values.contains(thread) else { return nil }
        
        do {
            return try fileIOStorage[thread] ?? {
                let idFileName = probablySafeThreadName(thread)
                let newTracer = try createNewTracer(fileName: idFileName)
                fileIOStorage[thread] = newTracer
                print("Created new thread tracer: \(newTracer)")
                return newTracer
            }()
        } catch {
            print("Tracer could not be created: \(thread), \(error)")
            failedThreads.append(thread)
            return nil
        }
    }
}

private extension PersistentThreadGroup {
    func probablySafeThreadName(_ thread: Thread) -> String {
        thread.threadName.components(separatedBy:
            .alphanumerics
            .inverted
        ).joined(separator: "_")
    }
    
    func createNewTracer(fileName: String) throws -> PersistentThreadTracer {
        print("Creating new thread tracer: \(fileName)")
        let newIDFile = AppFiles.createTraceIDFile(named: fileName)
        return try PersistentThreadTracer(
            idFileTarget: newIDFile,
            sourceMap: sharedSignatureMap
        )
    }
}
