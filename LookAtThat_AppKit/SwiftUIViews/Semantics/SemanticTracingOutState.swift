//
//  SemanticTracingOutState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI

class SemanticTracingOutState: ObservableObject {
    
    @Published var currentIndex = 0
    @Published var isSetup = false
    @Published var isWrapperLoaded = false
    @Published var isAutoPlaying = false
    
    @Published private var wrapper: SemanticMapTracer?
    private let tracer = TracingRoot.shared
    private lazy var cache = SemanticLookupCache(self)
    
    func startAutoPlay() {
        guard !isAutoPlaying else { return }
        isAutoPlaying = true
        QuickLooper(
            interval: .seconds(1),
            loop: { self.increment() }
        ).runUntil { !self.isAutoPlaying }
    }
    
    func stopAutoPlay() {
        isAutoPlaying = false
    }
    
    func increment() {
        toggleTrace(currentInfo?.maybeTrace)
        currentIndex += 1
        toggleTrace(currentInfo?.maybeTrace)
    }
    
    func decrement() {
        toggleTrace(currentInfo?.maybeTrace)
        currentIndex -= 1
        toggleTrace(currentInfo?.maybeTrace)
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
}

#if !TARGETING_SUI
extension SemanticTracingOutState {
    func setupTracing() {
        TracingRoot.shared.setupTracing()
        isSetup = true
    }
    
    func computeTraceInfo() {
        let cache = SceneLibrary.global.codePagesController.codeGridParser.gridCache
        let allGrid = cache.cachedGrids.values.map { $0.source }
        wrapper = SemanticMapTracer.wrapForLazyLoad(
            sourceGrids: allGrid,
            sourceTracer: TracingRoot.shared
        )
        isWrapperLoaded = true
    }
}
#else
extension SemanticTracingOutState {
    func computeTraceInfo() {
        print("\n\n\t\tTRACING DISABLED!\n\n")
    }
    
    func setupTracing() {
        print("\n\n\t\tTRACING DISABLED!\n\n")
    }
}
#endif

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
    
    var lastInfo2: TracedInfo? { self[lastIndex2] }
    var lastInfo: TracedInfo? { self[lastIndex] }
    var currentInfo: TracedInfo? { self[currentIndex] }
    var nextInfo: TracedInfo? { self[nextIndex] }
    var nextInfo2: TracedInfo? { self[nextIndex2] }
    
    var focusContext: [TracedInfo?] {
        [lastInfo2, lastInfo, currentInfo, nextInfo, nextInfo2]
    }
    
    func isCurrent(_ info: TracedInfo?) -> Bool {
        return info?.id == currentInfo?.id
    }
    
    func maybeInfoFromIndex(_ index: Int) -> TracedInfo? {
        let logSnapshot = tracer.logOutput.values
        guard logSnapshot.indices.contains(index) else {
            return nil
        }
        let output = logSnapshot[index]
        let maybeInfo = wrapper?.lookupInfo(output)
        return maybeInfo
    }
    
    private subscript(_ index: Int) -> TracedInfo? {
        cache[index]
    }
}

// Pass through index to use the easy cache semantics.
private class SemanticLookupCache: LockingCache<Int, TracedInfo?> {
    let sourceState: SemanticTracingOutState
    
    init(_ state: SemanticTracingOutState) {
        self.sourceState = state
        super.init()
    }
    
    override func make(_ key: Int, _ store: inout [Int : TracedInfo?]) -> TracedInfo? {
        sourceState.maybeInfoFromIndex(key)
    }
}
