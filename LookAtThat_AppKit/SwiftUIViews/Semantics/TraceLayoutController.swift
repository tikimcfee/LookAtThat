//
//  TraceLayoutController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/2/22.
//

import Foundation

class TraceLayoutController {
    let worldFocus: WorldGridFocusController
    var editor: WorldGridEditor { worldFocus.editor }
    var snapping: WorldGridSnapping { worldFocus.snapping }
    
    init(worldFocus: WorldGridFocusController) {
        self.worldFocus = worldFocus
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
        
        trace.grid.semanticInfoMap.doOnAssociatedNodes(
            trace.info.syntaxId,
            trace.grid.tokenCache
        ) { (info, nodes) in
            for node in nodes {
                UpdateNode(node, in: trace.grid) {
                    $0.addedColor += colorToAdd
                    $0.modelMatrix.translate(vector: positionToAdd)
                }
            }
        }
    }
}
