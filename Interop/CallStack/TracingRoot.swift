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
    func setupTracing() {
        SwiftTrace.logOutput.onOutput = onLog(_:)
        SwiftTrace.swiftDecorateArgs.onEntry = false
        SwiftTrace.swiftDecorateArgs.onExit = false
        SwiftTrace.typeLookup = true
        
        for tracingClass in FullTracingClassList {
            SwiftTrace.trace(aClass: tracingClass)
            let result = SwiftTrace.interpose(aType: tracingClass)
            print("Tracing Interposed '\(tracingClass)':, symbols: \(result)")
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

// TODO: Careful with recursive locks on main in the tracing route.
// AppendingStore has this problem, most tracing classes as well.
fileprivate let FullTracingClassList: [AnyClass] = [
    AppDelegate.self,
    AppStatePreferences.self,
    AppStatus.self,
    AtlasBuilder.self,
    AtlasPacking<UVRect>.self,
    AtlasPacking<VertexRect>.self,
    BackgroundQuad.self,
    BackgroundWorker.self,
    BoundsCaching.self,
    BoundsComputing.self,
    CodeGrid.self,
    CodeGridColors.self,
    CodeGridGlobalSemantics.self,
    CodeGridGlyphCollectionBuilder.self,
    CodeGridSelectionController.self,
    CodeGridTokenCache.self,
    CodePagesPopupEditorState.self,
    ConcurrentGridRenderer.self,
    ConnectionBundle.self,
    CustomMTKView.self,
    DebugCamera.self,
    DefaultInputReceiver.self,
    DepthStencilStateLibrary.Less.self,
    DepthStencilStateLibrary.self,
    DragSizableViewState.self,
    FlatteningVisitor.self,
    GestureShim.self,
    GitHubClient.self,
    GitHubClientViewState.self,
    GlobablWindowDelegate.self,
    GlobalInstances.self,
    GlobalNodeController.self,
    GlobalSearchViewState.self,
    GlobalSemanticParticipant.self,
    GlyphBuilder.self,
    GlyphCollection.Pointer.self,
    GlyphCollection.Renderer.self,
    GlyphCollection.self,
    GridCache.self,
    GridMeta.self,
    GridStore.self,
    InstanceCounter.self,
    IterativeRecursiveVisitor.self,
    JSSorter.self,
    KeyboardInterceptor.Positions.self,
    KeyboardInterceptor.self,
    KeyboardInterceptor.State.self,
    MagnifyStart.self,
    Match.self,
    MeshLibrary.self,
    MetalLink.self,
    MetalLinkAtlas.self,
    MetalLinkBaseMesh.self,
    MetalLinkGlyphNode.self,
    MetalLinkGlyphNodeBitmapCache.self,
    MetalLinkGlyphNodeCache.self,
    MetalLinkGlyphNodeMeshCache.self,
    MetalLinkGlyphTextureCache.self,
    MetalLinkHoverController.self,
    MetalLinkInstancedObject.self,
    MetalLinkInstancedObject.State.self,
    MetalLinkNode.self,
    MetalLinkObject.self,
    MetalLinkObject.State.self,
    MetalLinkPickingTexture.self,
    MetalLinkQuadMesh.self,
    MetalLinkRenderer.self,
    MetalLinkShaderCache.self,
    MetalLinkTriangleMesh.self,
    MetalView.Coordinator.self,
    ModifiersMagnificationGestureRecognizer.self,
    ModifiersPanGestureRecognizer.self,
    ModifierStore.self,
    Mouse.self,
    MultipeerConnectionManager.self,
    MultipeerStreamController.self,
    PeerConnection.self,
    QuickLooper.self,
    RenderPipelineDescriptorLibrary.self,
    RenderPipelineStateLibrary.self,
    RootNode.self,
    SafeDrawPass.self,
    SearchContainer.self,
    SearchFocusRenderTask.self,
    SemanticInfoBuilder.self,
    SemanticInfoMap.self,
    SemanticTracingOutState.self,
    SourceInfoPanelState.self,
    SplittingFileReader.self,
    SyntaxCache.self,
    TextureUVCache.self,
    ThreadInfoExtract.self,
    TouchState.self,
    TwoETimeRoot.self,
    UVRect.self,
    VertexDescriptorLibrary.self,
    VertexRect.self,
    VirtualGlyphParent.self,
    WatchWrap.self,
    WorkerPool.self,
    WorldGridEditor.self,
    WorldGridFocusController.self,
    WorldGridSnapping.self,
]
