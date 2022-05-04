//
//  SemanticTracingOutState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI
import Combine

class SemanticTracingOutState: ObservableObject {
    enum Sections: CaseIterable {
        case fullTraceList
        case logLoading
        case threadList
    }
    
    @Published private(set) var wrapper: SemanticMapTracer?
    
    @Published var isFileLoggingEnabled = false
    @Published var visibleSections: Set<Sections> = [.fullTraceList, .logLoading]
    func toggleSection(_ section: Sections) {
        if visibleSections.contains(section) {
            visibleSections.remove(section)
        } else {
            visibleSections.insert(section)
        }
    }
    
    @Published private(set) var traceLogFiles = [URL]()
    @Published private(set) var currentIndex = 0
    
    @Published var currentMatch = MatchedTraceOutput.indexFault(.init(position: -1))
    private var indexCache = ConcurrentDictionary<Int, MatchedTraceOutput>()
    
    @Published private(set) var focusTraceLines: PersistentThreadTracer?
    @Published private var focusedThread: Thread?
    @Published private var focusedFile: URL?
    
    @Published var isAutoPlaying = false
    @Published var interval = 1000.0
    let loopRange = 16.0...2000.0
    
    private let tracer = TracingRoot.shared
    private lazy var bag = Set<AnyCancellable>()
    
    init() {
        $isFileLoggingEnabled.sink {
            TracingRoot.shared.setWritingEnabled(isEnabled: $0)
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
                let loadedTrace = try TracingRoot.shared.loadTrace(from: url)
                print("Load completed for \(url); lines loaded = \(loadedTrace.count)")
                DispatchQueue.main.async {
                    print("Dispatched new trace for state")
                    self.indexCache = .init()
                    self.focusedThread = nil
                    self.focusedFile = url
                    self.focusTraceLines = loadedTrace
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
        print("\n\n\t\tDisabled thread setting!\n\n")
        focusedThread = thread
        focusedFile = nil
    }
    
    func increment() {
        currentIndex += 1
        currentMatch = self[currentIndex]
        highlightTrace(currentMatch.maybeTrace)
    }
    
    func decrement() {
        currentIndex -= 1
        currentMatch = self[currentIndex]
        highlightTrace(currentMatch.maybeTrace)
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
        
        SceneLibrary.global.codePagesController.zoom(to: trace.grid)
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
    
    func isCurrent(_ info: MatchedTraceOutput) -> Bool {
        return self[currentIndex].stamp == info.stamp
    }
    
    func isCurrent(_ thread: Thread?) -> Bool {
        return thread == focusedThread
    }
    
    func isCurrent(file: URL) -> Bool {
        return focusedFile == file
    }
}

// MARK: - Subscripting

#if TARGETING_SUI
extension SemanticTracingOutState: RandomAccessCollection {
    var startIndex: Int { return Self.randomTestData.startIndex }
    var endIndex: Int { return Self.randomTestData.endIndex }
    static var randomTestData = [MatchedTraceOutput]()
    
    subscript(_ index: Int) -> MatchedTraceOutput {
        return Self.randomTestData.indices.contains(index)
            ? Self.randomTestData[index]
        : .indexFault(.init(position: index))
    }
}
#else
extension SemanticTracingOutState: RandomAccessCollection {
    var startIndex: Int { return focusTraceLines?.startIndex ?? 0 }
    var endIndex: Int { return focusTraceLines?.endIndex ?? 0 }
    
    subscript(_ index: Int) -> MatchedTraceOutput {
        if let cached = indexCache[index] { return cached }
        
        guard let tracer = focusTraceLines,
              tracer.indices.contains(index),
              let matchedInfo = wrapper?.lookupInfo(tracer[index])
        else { return .indexFault(.init(position: index)) }

        indexCache[index] = matchedInfo
        return matchedInfo
    }
}
#endif
