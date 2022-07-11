//
//  TraceLog.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/23/22.
//

import Foundation
import SwiftSyntax
import AppKit

extension TracingRoot: TraceDelegate {
    class State: ObservableObject {
        @Published var traceWritesEnabled = false
    }
    
    var writesEnabled: Bool {
        get { state.traceWritesEnabled }
        set {
            print("<!> Thread trace writes: enabled=\(newValue)")
            state.traceWritesEnabled = newValue
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
        BaseSceneController.self,
        BoundsComputing.self,
        CodeGrid.AttributedGlyphs.self,
        CodeGrid.Measures.self,
        CodeGrid.Pointer.self,
        CodeGrid.RawGlyphs.self,
        CodeGrid.Renderer.self,
        CodeGrid.Writer.self,
        CodeGrid.self,
        CodeGridColors.self,
        CodeGridControl.self,
        CodeGridFocusController.self,
        CodeGridGlobalSemantics.self,
        CodeGridHoverController.self,
        CodeGridInfoViewSingleState.self,
        CodeGridInfoViewState.self,
        CodeGridParser.self,
        CodeGridParserQueryController.self,
        CodeGridPointerController.self,
        CodeGridSelectionController.self,
        CodeGridSemanticMap.self,
        CodeGridTokenCache.self,
        CodeGridTraceController.self,
        CodeGridUserFocusController.self,
        CodeGridWorld.self,
        CodePagesController.self,
        CodePagesControllerMacOSCompat.self,
        CodePagesControllerMacOSInputCompat.self,
        CodePagesInput.self,
        CodePagesPopupEditorState.self,
        ConcurrentGridRenderer.self,
        ConnectionBundle.self,
        CustomSceneView.self,
        CustomSceneView.self,
        DragSizableViewState.self,
        DragonAnimationLoop.self,
        FileBrowser.self,
        FlatteningVisitor.self,
        FocusBox.self,
        FocusBoxControl.self,
        FocusBoxEngineMacOS.self,
        FocusCache.self,
        FocusSearchInputView.State.self,
        GestureShim.self,
        GlobablWindowDelegate.self,
        GlobalSemanticParticipant.self,
        GlyphBuilder.self,
        GlyphLayerCache.self,
        GlyphNode.self,
        GridCache.self,
        HighlightCache.self,
        HitTestEvaluator.self,
        HoverClones.self,
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
        TokenHoverInteractionTracker.self,
        TouchStart.self,
        TouchState.self,
        TraceCapturingRewriter.self,
        TraceFileWriter.self,
        TracingFileFinder.self,
        VersionNumber.self,
        WatchWrap.self,
        WireDataTransformer.self,
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
