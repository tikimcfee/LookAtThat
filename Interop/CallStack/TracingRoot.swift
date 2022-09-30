//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import SwiftSyntax
import AppKit
import Combine

extension TracingRoot {
    class State: ObservableObject {
        @Published var traceWritesEnabled = false
        @Published var didEnableTracing = false
        private var bag = Set<AnyCancellable>()
        
        init() {
            $traceWritesEnabled.dropFirst().sink {
                PersistentThreadTracer.SHOULD_WRITE = $0
            }.store(in: &bag)
        }
    }
}

class TracingRoot {
    static var shared = TracingRoot()
    
    lazy var capturedLoggingThreads = ConcurrentDictionary<Thread, Int>()
    lazy var capturedLoggingQueues = ConcurrentDictionary<String, Int>()
    let tracingConsumer = TracingRootConsumer()
    let state = State()
    
    private init() {
        
    }
    
    func onLog(_ out: TraceOutput) {
        capturedLoggingThreads[Thread.current] = 1
        capturedLoggingQueues[currentQueueName()] = 1
        tracingConsumer.storeTraceLog(out)
    }
    
    func getCurrentQueueTraceLogs() -> PersistentThreadTracer? {
        tracingConsumer.getTraceLogs()
    }
    
    func loadTrace(from file: URL) throws -> PersistentThreadTracer {
        try tracingConsumer.threadTracer(from: file)
    }
    
    func addRandomEvent() {
        tracingConsumer.addRandomEvent()
    }
    
    func commitMappingState() {
        tracingConsumer.commitGroupTracerState()
    }
    
    func removeAllTraces() {
        tracingConsumer.removeAllLogTraces()
    }
    
    func removeMapping() {
        tracingConsumer.removeMapping()
    }
}

#if !TARGETING_SUI && !StripSwiftTrace
import SwiftTrace
extension TracingRoot {
    static let trackedTypes: [AnyClass] = [
        AppDelegate.self,
        AppStatePreferences.self,
        BackgroundWorker.self,
        BoundsComputing.self,
        CodeGrid.self,
        CodeGridColors.self,
        CodeGridGlobalSemantics.self,
        SemanticInfoMap.self,
        CodeGridTokenCache.self,
        CodePagesPopupEditorState.self,
        ConcurrentGridRenderer.self,
        ConnectionBundle.self,
        DragSizableViewState.self,
        FileBrowser.self,
        FlatteningVisitor.self,
        GestureShim.self,
        GlobablWindowDelegate.self,
        GlobalSemanticParticipant.self,
        GlyphBuilder.self,
        GlyphNode.self,
        GridCache.self,
        IterativeRecursiveVisitor.self,
        KeyboardInterceptor.self,
        MagnifyStart.self,
        Match.self,
        ModifierStore.self,
        ModifiersMagnificationGestureRecognizer.self,
        ModifiersPanGestureRecognizer.self,
        Mouse.self,
        MultipeerConnectionManager.self,
        MultipeerStreamController.self,
        PeerConnection.self,
        QuickLooper.self,
        SearchContainer.self,
        SemanticInfoBuilder.self,
        SemanticMapTracer.self,
        SemanticTracingOutState.self,
        SourceInfoPanelState.self,
        SyntaxCache.self,
        TouchState.self,
        TraceCapturingRewriter.self,
        TraceFileWriter.self,
        TracingFileFinder.self,
        WatchWrap.self,
        WorkerPool.self,
        WorldGridEditor.self,
        WorldGridSnapping.self,
        MetalLinkHoverController.self,
        MetalLink.self,
        MetalLinkGlyphNode.self,
        GlyphCollection.self,
    ]
    
    func setupTracing() {
        SwiftTrace.logOutput.onOutput = onLog(_:)
        SwiftTrace.swiftDecorateArgs.onEntry = false
        SwiftTrace.swiftDecorateArgs.onExit = false
        SwiftTrace.typeLookup = true
        Self.trackedTypes.forEach {
            SwiftTrace.trace(aClass: $0)
            let parser = SwiftTrace.interpose(aType: $0)
            print("interposed '\($0)': \(parser)")
        }
    }
    
    func stopTracingAll() {
        SwiftTrace.revertInterposes()
        SwiftTrace.removeAllTraces()
    }
}
#else
extension TracingRoot {
    func setupTracing() {
        print("\n\n\t\t Tracing is disabled!")
    }
}
#endif
