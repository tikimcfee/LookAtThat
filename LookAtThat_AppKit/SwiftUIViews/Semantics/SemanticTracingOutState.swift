//
//  SemanticTracingOutState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI
import Combine

class SemanticTracingOutState: ObservableObject {
    
    @Published private(set) var wrapper: SemanticMapTracer?
    
    @Published var isFileLoggingEnabled = false
    @Published private(set) var traceLogFiles = [URL]()
    @Published private(set) var focusContext = [MatchedTraceOutput]()
    @Published private(set) var currentIndex = 0
    @Published private(set) var focusTraceLines: PersistentThreadTracer?
    @Published private(set) var focusTrace: MatchedTraceOutput?
    var focusedThread: Thread?
    var focusedFile: URL?
    
    @Published var isAutoPlaying = false
    @Published var interval = 1000.0
    let loopRange = 16.0...2000.0
    
    private let tracer = TracingRoot.shared
    private lazy var cache = SemanticLookupCache(self)
    private lazy var bag = Set<AnyCancellable>()
    
    init() {
        $isFileLoggingEnabled.sink {
            PersistentThreadTracer.AllWritesEnabled = $0
        }.store(in: &bag)
    }
        
    var loggedThreads: [Thread] {
        tracer.capturedLoggingThreads.keys.sorted(by: {
            $0.threadName < $1.threadName
        })
    }
    
    var wrapperInfo: String {
        wrapper.map {
            "\($0.sourceGrids.count) grids, \($0.matchedReferenceCache.count) call names"
        } ?? "No loaded query wrapper"
    }
    
    var threadSlices: [ArraySlice<Thread>] {
        loggedThreads.slices(sliceSize: 5)
    }
    
    func reloadTraceFiles() {
        traceLogFiles = AppFiles.allTraceFiles()
    }
    
    func loadTrace(at url: URL) {
        WorkerPool.shared.nextConcurrentWorker().async {
            print("Starting trace load at \(url)")
            do {
                let loadedTrace = try Thread.threadTracer(from: url)
                print("Load completed for \(url); lines loaded = \(loadedTrace.count)")
                DispatchQueue.main.async {
                    print("Dispatched new trace for state")
                    self.focusedThread = nil
                    self.focusedFile = url
                    self.resetTraceLines(loadedTrace)
                }
            } catch {
                print("ThreadTracer load error", error)
            }
        }
    }
    
    func startAutoPlay() {
        guard !isAutoPlaying else { return }
        isAutoPlaying = true
        let looper = QuickLooper(
            interval: .milliseconds(Int(interval)),
            loop: { self.increment() }
        )
        looper.runUntil { !self.isAutoPlaying }
        
        $interval.sink { newTime in
            looper.interval = .milliseconds(Int(newTime))
        }.store(in: &bag)
    }
    
    func stopAutoPlay() {
        isAutoPlaying = false
        bag.removeAll()
    }
    
    func setCurrentThread(_ thread: Thread) {
        focusedThread = thread
        focusedFile = nil
        resetTraceLines(thread.getTraceLogs())
    }
    
    func increment() {
        currentIndex += 1
        highlightTrace(self[currentIndex]?.maybeTrace)
    }
    
    func decrement() {
        currentIndex -= 1
        highlightTrace(self[currentIndex]?.maybeTrace)
    }
    
    private func resetTraceLines(_ newTracker: PersistentThreadTracer?) {
        cache.lockAndDo { $0.removeAll(keepingCapacity: true) }
        focusTraceLines = newTracker
        currentIndex = 0
    }
}

// MARK: - Scene interactions

extension SemanticTracingOutState {
    func toggleTrace(_ trace: TraceValue) {
        trace.grid.toggleGlyphs()
        SceneLibrary.global.codePagesController.selected(
            id: trace.info.syntaxId,
            in: trace.grid.codeGridSemanticInfo
        )
    }
    
    func zoomTrace(_ trace: TraceValue?) {
        guard let trace = trace else {
            return
        }
        
        SceneLibrary.global.codePagesController.moveExecutionPointer(
            id: trace.info.syntaxId,
            in: trace.grid
        )
    }
    
    func highlightTrace(_ trace: TraceValue?) {
        guard let trace = trace else {
            return
        }
        
        SceneLibrary.global.codePagesController.setNewFocus(
            id: trace.info.syntaxId,
            in: trace.grid
        )
    }
}

//MARK: - Setup State Changes

extension SemanticTracingOutState {
    func setupTracing() {
        tracer.setupTracing()
    }
    
    func reloadQueryWrapper() {
        let cache = SceneLibrary.global.codePagesController.codeGridParser.gridCache
        let allGrid = cache.cachedGrids.values.map { $0.source }
        wrapper = SemanticMapTracer.wrapForLazyLoad(
            sourceGrids: allGrid,
            sourceTracer: tracer
        )
    }
}

//MARK: - Index Convencience

extension SemanticTracingOutState {
    
    func isCurrent(_ info: MatchedTraceOutput?) -> Bool {
        return info?.maybeFoundInfo?.syntaxId
            == focusTrace?.maybeFoundInfo?.syntaxId
    }
    
    func isCurrent(_ thread: Thread?) -> Bool {
        return thread == focusedThread
    }
    
    func isCurrent(file: URL) -> Bool {
        return focusedFile == file
    }
    
    func maybeInfoFromFocusedTraceLines(at index: Int) -> MatchedTraceOutput? {
        guard let tracer = focusTraceLines else { return nil }
        guard tracer.indices.contains(index) else { return nil }
        let output = tracer[index]
        let maybeInfo = wrapper?.lookupInfo(output)
        return maybeInfo
    }
}

// MARK: - Lookup Cache

// Pass through index to use the easy cache semantics.
private class SemanticLookupCache: LockingCache<Int, MatchedTraceOutput?> {
    let sourceState: SemanticTracingOutState
    
    init(_ state: SemanticTracingOutState) {
        self.sourceState = state
        super.init()
    }
    
    override func make(
        _ key: Int,
        _ store: inout [Int : MatchedTraceOutput?]
    ) -> MatchedTraceOutput? {
        sourceState.maybeInfoFromFocusedTraceLines(at: key)
    }
}

// MARK: - Subscripting

#if TARGETING_SUI
extension SemanticTracingOutState {
    static var randomTestData = [MatchedTraceOutput]()
    subscript(_ index: Int) -> MatchedTraceOutput? {
        return Self.randomTestData.indices.contains(index)
            ? Self.randomTestData[index]
            : nil
    }
}
#else
extension SemanticTracingOutState {
    subscript(_ index: Int) -> MatchedTraceOutput? {
        cache[index]
    }
}
#endif
