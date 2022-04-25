//
//  SemanticTracingOutState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI
import Combine

class SemanticTracingOutState: ObservableObject {
    @Published var currentIndex = 0
    @Published var isSetup = false
    @Published var isWrapperLoaded = false
    @Published var wrapper: SemanticMapTracer?
    @Published var isAutoPlaying = false
    @Published var interval = 1000.0
    let loopRange = 100.0...2000.0
    
    private let tracer = TracingRoot.shared
    private lazy var cache = SemanticLookupCache(self)
    private lazy var bag = Set<AnyCancellable>()
    
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

//extension TracedInfo: Identifiable, Hashable {
//    static func == (lhs: TracedInfo, rhs: TracedInfo) -> Bool {
//        lhs.id == rhs.id
//        && lhs.thread == rhs.thread
//    }
//
//    var id: String {
//        return maybeFoundInfo?.syntaxId.stringIdentifier ?? "<no_id>"
//    }
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//}

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
    
    func maybeInfoFromIndex(_ index: Int) -> MatchedTraceOutput? {
        let logSnapshot = tracer.logOutput.values
        guard logSnapshot.indices.contains(index) else {
            return nil
        }
        let output = logSnapshot[index]
        let maybeInfo = wrapper?.lookupInfo(output)
        return maybeInfo
    }
    
#if TARGETING_SUI
    static var randomTestData = [MatchedTraceOutput]()
    private subscript(_ index: Int) -> MatchedTraceOutput? {
        return Self.randomTestData.indices.contains(index)
            ? Self.randomTestData[index]
            : nil
    }
#else
    private subscript(_ index: Int) -> MatchedTraceOutput? {
        cache[index]
    }
#endif
    
}

// Pass through index to use the easy cache semantics.
private class SemanticLookupCache: LockingCache<Int, MatchedTraceOutput?> {
    let sourceState: SemanticTracingOutState
    
    init(_ state: SemanticTracingOutState) {
        self.sourceState = state
        super.init()
    }
    
    override func make(_ key: Int, _ store: inout [Int : MatchedTraceOutput?]) -> MatchedTraceOutput? {
        sourceState.maybeInfoFromIndex(key)
    }
}
