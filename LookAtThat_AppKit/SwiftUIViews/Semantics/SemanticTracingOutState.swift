//
//  SemanticTracingOutState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/24/22.
//

import SwiftUI
import Combine
import SCNLine
import SceneKit

class TraceLineIncrementalTracker {
    var visualExecutionPath: SCNLineNode
    
    init() {
        self.visualExecutionPath = SCNLineNode(
            radius: 4.0
        )
        CodePagesController.shared
            .sceneState
            .rootGeometryNode
            .addChildNode(visualExecutionPath)
    }
    
    deinit {
        visualExecutionPath.removeFromParentNode()
    }
    
    func handleMatch(_ match: MatchedTraceOutput) {
        switch match {
        case .found(let found):
            handleFound(found)
        default:
            break
        }
    }
    
    func handleFound(_ found: MatchedTraceOutput.Found) {
        if found.out.isEntry {
            let position = representativePosition(for: found.trace)
            visualExecutionPath.add(point: position)
//            CodePagesController.shared
//                .sceneState
//                .cameraNode.look(
//                    at: position,
//                    up: CodePagesController.shared.sceneState.rootGeometryNode.worldUp,
//                    localFront: SCNNode.localFront
//                )
        } else {
            visualExecutionPath.remove(index: visualExecutionPath.points.endIndex - 1)
        }
    }
    
    func representativePosition(for value: TraceValue) -> SCNVector3 {
        let computing = BoundsComputing()
        value.grid.codeGridSemanticInfo
            .doOnAssociatedNodes(value.info.syntaxId, value.grid.tokenCache) { info, nodeSet in
                nodeSet.forEach { node in
                    computing.consumeBounds(node.worldBounds)
                }
            }
        return computing.bounds.min
    }
    
//    func circumscribeNodes(for value: TraceValue) {
//        visualExecutionPath.removeFromParentNode()
//        visualExecutionPath = SCNLineNode()
//        CodePagesController.shared
//            .sceneState
//            .rootGeometryNode
//            .addChildNode(visualExecutionPath)
//
//        // Convert to root geometry node space
//        let root = CodePagesController.shared
//            .sceneState
//            .rootGeometryNode
//
//        let bounds = BoundsComputing()
//        value.grid.codeGridSemanticInfo
//            .doOnAssociatedNodes(value.info.syntaxId, value.grid.tokenCache) { info, nodeSet in
//                nodeSet.forEach { node in
//                    bounds.consumeBounds(node.worldBounds)
//                }
//            }
//
//        visualExecutionPath.add(points: [
//            .init(x: bounds.minX, y: bounds.maxY, z: bounds.maxZ),
//            .init(x: bounds.maxX, y: bounds.maxY, z: bounds.maxZ),
//            .init(x: bounds.maxX, y: bounds.minY, z: bounds.maxZ),
//            .init(x: bounds.minX, y: bounds.minY, z: bounds.maxZ),
//            .init(x: bounds.minX, y: bounds.maxY, z: bounds.maxZ)
//        ])
//    }
}

class SemanticTracingOutState: ObservableObject {
    enum Sections: CaseIterable {
        case fullTraceList
        case logLoading
        case threadList
    }
    
    @Published private(set) var wrapper: SemanticMapTracer?
    @Published var visibleSections: Set<Sections> = []
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
    var tracerState: TracingRoot.State { tracer.state }
    private lazy var bag = Set<AnyCancellable>()
    private lazy var lineTracker = TraceLineIncrementalTracker()
    
    
    init() {
        // Tracer isn't observable; sink from it manually
        tracerState.$traceWritesEnabled
            .sink { _ in self.objectWillChange.send() }
            .store(in: &bag)
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
        highlightTrace()
    }
    
    func decrement() {
        currentIndex -= 1
        currentMatch = self[currentIndex]
        highlightTrace()
    }
}

// MARK: - Scene interactions

extension SemanticTracingOutState {
    func toggleTrace(_ trace: TraceValue) {
        trace.grid.toggleGlyphs()
        CodePagesController.shared.selection.selected(
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
    
    func highlightTrace() {
        guard case let MatchedTraceOutput.found(found) = currentMatch else {
            return
        }
        
        let currentTrace = found.trace
        CodePagesController.shared.trace.updateFocus(
            id: currentTrace.info.syntaxId,
            in: currentTrace.grid,
            focus: currentMatch.out.isEntry
        )
        
        lineTracker.handleFound(found)
        
//        CodePagesController.shared.compat.doOnTargetFocus { controller, box in
//            if box.depthOf(grid: currentTrace.grid) == box.deepestDepth {
//                return
//            }
//            if box.contains(grid: currentTrace.grid) {
//                box.bringToDeepest(currentTrace.grid)
//            } else {
//                controller.appendToTarget(grid: currentTrace.grid)
//            }
//        }
    }
}

//MARK: - Setup State Changes

extension SemanticTracingOutState {
    func setupTracing() {
        print("\n\n\t\t!!!! Tracing is enabled !!!!\n\n\t\tPrepare your cycles!\n\n")
        tracer.state.traceWritesEnabled = true
        tracer.removeAllTraces()
        tracer.removeMapping()
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
