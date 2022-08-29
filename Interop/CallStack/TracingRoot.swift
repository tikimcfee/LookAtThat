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
        CodeGrid.Measures.self,
        CodeGrid.self,
        CodeGridColors.self,
        CodeGridGlobalSemantics.self,
        CodeGridParser.self,
        CodeGridParserQueryController.self,
        SemanticInfoMap.self,
        CodeGridTokenCache.self,
        CodeGridWorld.self,
        CodePagesController.self,
        CodePagesPopupEditorState.self,
        ConcurrentGridRenderer.self,
        ConnectionBundle.self,
        CustomSceneView.self,
        CustomSceneView.self,
        DragSizableViewState.self,
        FileBrowser.self,
        FlatteningVisitor.self,
        GestureShim.self,
        GlobablWindowDelegate.self,
        GlobalSemanticParticipant.self,
        GlyphBuilder.self,
        GlyphNode.self,
        GridCache.self,
        InterpolatorFunctions.self,
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
        Point3.self,
        QuickLooper.self,
        RawSensorData.self,
        RawSensorDataParser.self,
        RawSensorState.self,
        RecurseState.self,
        SCNBezierPath.self,
        SceneLibrary.self,
        SceneState.self,
        SearchContainer.self,
        SemanticInfoBuilder.self,
        SemanticMapTracer.self,
        SemanticTracingOutState.self,
        SourceInfoPanelState.self,
        StartingTapDelegate.self,
        SyntaxCache.self,
        TouchState.self,
        TraceCapturingRewriter.self,
        TraceFileWriter.self,
        TracingFileFinder.self,
        VersionNumber.self,
        WatchWrap.self,
        WorkerPool.self,
        WorldGridEditor.self,
        WorldGridNavigator.self,
        WorldGridSnapping.self,
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
}
#else
extension TracingRoot {
    func setupTracing() {
        print("\n\n\t\t Tracing is disabled!")
    }
}
#endif
