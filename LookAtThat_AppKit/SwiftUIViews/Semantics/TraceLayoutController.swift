//
//  TraceLayoutController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/2/22.
//

import Foundation
import MetalLink

class TraceLayoutController {
    let worldFocus: WorldGridFocusController
    var editor: WorldGridEditor { worldFocus.editor }
    var snapping: WorldGridSnapping { worldFocus.snapping }
    
    lazy var currentTraceLine = MetalLinkLine(worldFocus.link)
    
    init(worldFocus: WorldGridFocusController) {
        self.worldFocus = worldFocus
        currentTraceLine.setColor(LFloat4(1, 0, 0, 0))
    }
    
    // reg1 will be last entry grid
    var lastEntryGrid: CodeGrid? {
        get { snapping.gridReg1 }
        set { snapping.gridReg1 = newValue }
    }
    
    // reg2 will be last exit grid
    var lastExitGrid: CodeGrid? {
        get { snapping.gridReg2 }
        set { snapping.gridReg2 = newValue }
    }
    
    func onNext(traceOutput: MatchedTraceOutput) {
        guard let value = traceOutput.maybeTrace else {
            return
        }
        
        updateHighlight(
            trace: value,
            setFocused: traceOutput.out.isEntry
        )
        
        if traceOutput.out.isEntry {
            onTraceEntry(traceOutput, value)
        } else {
            onTraceExit(traceOutput, value)
        }
    }
    
    func onTraceEntry(_ traceOutput: MatchedTraceOutput, _ value: TraceValue) {
        lastEntryGrid = value.grid
    }
    
    func onTraceExit(_ traceOutput: MatchedTraceOutput, _ value: TraceValue) {
        lastExitGrid = value.grid
        currentTraceLine.popSegment()
    }
    
    private let focusAddColor = LFloat4(0.2, 0.2, 0.2, 1.0)
    private let focusSubColor = -LFloat4(0.2, 0.2, 0.2, 1.0)
    private let focusAddPosition = LFloat3(0.0, 0.0, 2.0)
    private let focusSubPosition = -LFloat3(0.0, 0.0, 2.0)
    
    func updateHighlight(
        trace: TraceValue,
        setFocused: Bool
    ) {
        let colorToAdd = setFocused
        ? focusAddColor
        : focusSubColor
        
        let positionToAdd = setFocused
        ? focusAddPosition
        : focusSubPosition
        
        // TODO: worldBounds don't quite work as expected. Compute topLeft manually.
        var topLeft = LFloat3(.infinity, -.infinity, 0)
        
        collectTraceNodes(trace: trace) { node in
            if hasFurtherLeading(node.worldPosition, topLeft) {
                topLeft = node.worldPosition
            }
            
            UpdateNode(node, in: trace.grid) {
                $0.addedColor += colorToAdd
                $0.modelMatrix.translate(vector: positionToAdd)
            }
        }
        
        if setFocused {
//            var topLeft = LFloat3(bounds.minX, bounds.maxY, bounds.maxZ)
//            topLeft = trace.grid.convertPosition(topLeft, to: nil)
            currentTraceLine.appendSegment(about: topLeft)
        }
    }
    
    func jumpCameraToTrace(_ trace: TraceValue) {
        // TODO: worldBounds don't quite work as expected. Compute topLeft manually.
        var topLeft = LFloat3(.infinity, -.infinity, 0)
        var didSet = false
        
//        let computing = BoxComputing()
        
        collectTraceNodes(trace: trace) { node in
            if hasFurtherLeading(node.worldPosition, topLeft) {
                topLeft = node.worldPosition
                didSet = true
            }
//            computing.consumeBounds(node.worldBounds)
        }
        
        if didSet {
            GlobalInstances.debugCamera.interceptor.resetPositions()
            GlobalInstances.debugCamera.position = topLeft.translated(dX: 16, dZ: 32)
            GlobalInstances.debugCamera.rotation = .zero
        }
        
//        if computing.didSetInitial {
//            let final = computing.bounds
//            let lookPosition = LFloat3(
//                final.min.x + (BoundsWidth(final) / 2.0),
//                final.max.y - (BoundsHeight(final) / 2.0),
//                -8.0
//            )
//            GlobalInstances.debugCamera.interceptor.resetPositions()
//            GlobalInstances.debugCamera.position = lookPosition
//            GlobalInstances.debugCamera.rotation = .zero
//        }
    }
    
    private func hasFurtherLeading(_ l: LFloat3, _ r: LFloat3) -> Bool {
        l.x < r.x && l.y > r.y
    }
    
    private func hasFurtherTrailing(_ l: LFloat3, _ r: LFloat3) -> Bool {
        l.x < r.x && l.y > r.y
    }
    
    private func collectTraceNodes(
        trace: TraceValue,
        onEach: (GlyphNode) -> Void
    ) {
        trace.grid.semanticInfoMap.doOnAssociatedNodes(
            trace.info.syntaxId,
            trace.grid.tokenCache
        ) { (info, nodes) in
            for node in nodes {
                onEach(node)
            }
        }
    }
}
