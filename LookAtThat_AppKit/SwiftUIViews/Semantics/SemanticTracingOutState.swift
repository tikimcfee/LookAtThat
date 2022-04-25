//
//  SemanticTracingOutState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI
import Combine

#if !TARGETING_SUI
import SwiftTrace
#endif

class SemanticTracingOutState: ObservableObject {
    @Published var currentIndex = 0
    @Published var isSetup = false
    @Published var isWrapperLoaded = false
    @Published var wrapper: SemanticMapTracer?
    @Published var focusedThread: Thread?
    
    @Published var isAutoPlaying = false
    @Published var interval = 1000.0
    let loopRange = 100.0...2000.0
    
    private let tracer = TracingRoot.shared
    private lazy var cache = SemanticLookupCache(self)
    private lazy var bag = Set<AnyCancellable>()
        
    var loggedThreads: [Thread] {
        tracer.capturedLoggingThreads.keys.sorted(by: {
            $0.queueName < $1.queueName
        })
//        return [Thread(), Thread(), Thread(), Thread(), Thread()]
    }
    
    func logs(for thread: Thread) -> [(TraceOutput, Thread)] {
        // It's on `thread`, but using it here for now to do other transforms if needed
        return thread.getTraceLogs()
    }
    
    func startAutoPlay() {
        guard !isAutoPlaying else { return }
        isAutoPlaying = true
        var looper = QuickLooper(
            interval: .seconds(1),
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
    
    func increment() {
        currentIndex += 1
        zoomTrace(currentInfo?.maybeTrace)
    }
    
    func decrement() {
        currentIndex -= 1
        zoomTrace(currentInfo?.maybeTrace)
    }
    
    func toggleTrace(_ trace: TraceValue?) {
        guard let trace = trace else {
            return
        }
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
        SceneLibrary.global.codePagesController.zoom(
            id: trace.info.syntaxId,
            in: trace.grid
        )
    }
}

extension SemanticTracingOutState {
    func setupTracing() {
        tracer.setupTracing()
        isSetup = true
    }
    
    func prepareQueryWrapper() {
        let cache = SceneLibrary.global.codePagesController.codeGridParser.gridCache
        let allGrid = cache.cachedGrids.values.map { $0.source }
        wrapper = SemanticMapTracer.wrapForLazyLoad(
            sourceGrids: allGrid,
            sourceTracer: tracer
        )
        isWrapperLoaded = true
    }
}

//MARK: - View properties
extension SemanticTracingOutState {
    func threadSelectionText(_ thread: Thread) -> String {
        "[\(thread.threadName) | \(thread.queueName)]"
    }
}

//MARK: - Index Convencience

extension SemanticTracingOutState {
    private var lastIndex2: Int { currentIndex - 2 }
    private var lastIndex: Int { currentIndex - 1 }
    private var nextIndex: Int { currentIndex + 1 }
    private var nextIndex2: Int { currentIndex + 2 }
    
    var lastInfo2: MatchedTraceOutput? { self[lastIndex2] }
    var lastInfo: MatchedTraceOutput? { self[lastIndex] }
    var currentInfo: MatchedTraceOutput? { self[currentIndex] }
    var nextInfo: MatchedTraceOutput? { self[nextIndex] }
    var nextInfo2: MatchedTraceOutput? { self[nextIndex2] }
    
    var focusContext: [MatchedTraceOutput?] {
        [lastInfo2, lastInfo, currentInfo, nextInfo, nextInfo2]
    }
    
    func isCurrent(_ info: MatchedTraceOutput?) -> Bool {
        return info?.id == currentInfo?.id
    }
    
    func isCurrent(_ thread: Thread?) -> Bool {
        return thread == focusedThread
    }
    
    func maybeInfoFromIndex(_ index: Int) -> MatchedTraceOutput? {
        guard let thread = focusedThread else {
            print("No thread focused")
            return nil
        }
        
        let outputSnapshot = thread.getTraceLogs()
        guard outputSnapshot.indices.contains(index) else {
            return nil
        }
        
        let output = outputSnapshot[index]
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
        sourceState.maybeInfoFromIndex(key)
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
