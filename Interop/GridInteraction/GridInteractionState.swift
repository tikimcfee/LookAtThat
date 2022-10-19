//
//  LinkLanguageServer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/16/22.
//

import Foundation
import Combine

class GridInteractionState {
    var bag = Set<AnyCancellable>()
    
    private var lockedNodeEvent: NodePickingState.Event = .initial
    private var lockedGridEvent: GridPickingState.Event = .initial
    
    let hoverController: MetalLinkHoverController
    let input: DefaultInputReceiver
    
    init(
        hoverController: MetalLinkHoverController,
        input: DefaultInputReceiver
    ) {
        self.hoverController = hoverController
        self.input = input
    }
    
    func setupStreams() {
        let glyphStream = hoverController.sharedGlyphEvent
        let gridStream = hoverController.sharedGridEvent
        let mouseStream = input.sharedMouseDown
        
        mouseStream
            .combineLatest(
                glyphStream,
                gridStream
            )
            .sink { _, glyphEvent, gridEvent in
                self.lockedNodeEvent = glyphEvent
                self.lockedGridEvent = gridEvent
            }
        .store(in: &bag)
        
        glyphStream
            .sink { glyph in
                self.handleNodeEvent(glyph)
            }
        .store(in: &bag)
    }
}

private extension GridInteractionState {
    func handleNodeEvent(
        _ glyphEvent: NodePickingState.Event
    ) {
        switch glyphEvent {
        case let (.foundNew(.none, newGlyph)):
            focusGlyphState(newGlyph)
            
        case let (.foundNew(.some(lastGlyph), newGlyph)):
            defocusGlyphState(lastGlyph)
            focusGlyphState(newGlyph)
            
        default:
            break
        }
    }
    
    func focusGlyphState(_ nodeState: NodePickingState) {
        updateGlyphState(nodeState) {
            $0.addedColor += LFloat4(0.0, 0.3, 0.0, 0.0)
        }
    }
    
    func defocusGlyphState(_ nodeState: NodePickingState) {
        updateGlyphState(nodeState) {
            $0.addedColor -= LFloat4(0.0, 0.3, 0.0, 0.0)
        }
    }
    
    private func updateGlyphState(_ pickingState: NodePickingState, _ action: (inout GlyphConstants) -> Void) {
        guard let pickedNodeSyntaxID = pickingState.parserSyntaxID
        else { return }
        
        pickingState.targetGrid.updateAssociatedNodes(pickedNodeSyntaxID) { node, constants, _ in
            action(&constants)
        }
    }
}
