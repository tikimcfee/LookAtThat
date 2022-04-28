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
    @Published var isSetup = false
    @Published var isWrapperLoaded = false
    @Published var wrapper: SemanticMapTracer?
    @Published var focusedThread: Thread? { didSet { resetFocus() } }
    
    @Published var focusContext = [MatchedTraceOutput]()
    private var focusTrace: MatchedTraceOutput?
    @Published var currentIndex = 0
    
    @Published var isAutoPlaying = false
    @Published var interval = 1000.0
    let loopRange = 100.0...2000.0
    
    private let tracer = TracingRoot.shared
    private lazy var cache = SemanticLookupCache(self)
    private lazy var bag = Set<AnyCancellable>()
        
    var loggedThreads: [Thread] {
        tracer.capturedLoggingThreads.keys.sorted(by: {
            $0.threadName < $1.threadName
        })
    }
    
    var slices: [ArraySlice<Thread>] {
        loggedThreads.slices(sliceSize: 5)
    }
    
    func logs(for thread: Thread) -> [(TraceOutput, Thread, String)] {
        // It's on `thread`, but using it here for now to do other transforms if needed
        return thread.getTraceLogs()
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
    
    func increment() {
        currentIndex += 1
        zoomTrace(self[currentIndex]?.maybeTrace)
        resetFocus()
    }
    
    func decrement() {
        currentIndex -= 1
        zoomTrace(self[currentIndex]?.maybeTrace)
        resetFocus()
    }
    
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
    
    func resetFocus() {
        // lookahead and skip repeated cache entries
        var newFocusTrace: MatchedTraceOutput?
        var final = [MatchedTraceOutput]()
        let lookAheadMax = 128
        let goalSize = 10
        var offset = 0
        
        while offset < lookAheadMax && final.count < goalSize {
            defer {
                offset += 1
//                print("\t\tNew offset: \(offset)")
            }
            
            let focusIndex = currentIndex + offset
            
            guard let matchAtIndex = self[focusIndex] else {
//                print("Missing: \(focusIndex)")
                continue
            }
            
            if final.last?.out.callComponents.callPath == matchAtIndex.out.callComponents.callPath {
//                print("Skip: \(matchAtIndex.out.name) \(matchAtIndex.out.callComponents.callPath)")
                continue
            }
            
            if newFocusTrace == nil {
                newFocusTrace = matchAtIndex
//                print("Set focus: \(matchAtIndex.out.callComponents.callPath)")
            }
            
//            print("Found for focus: \(matchAtIndex.out.callComponents.callPath)")
            final.append(matchAtIndex)
        }
        
        self.focusTrace = newFocusTrace
        self.focusContext = final
    }
}

//MARK: - Setup State Changes

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

//MARK: - Index Convencience

extension SemanticTracingOutState {
    
    func isCurrent(_ info: MatchedTraceOutput?) -> Bool {
        return info?.maybeFoundInfo?.syntaxId
            == focusTrace?.maybeFoundInfo?.syntaxId
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
