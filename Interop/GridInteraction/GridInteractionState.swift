//
//  LinkLanguageServer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/16/22.
//

import Foundation
import Combine
import MetalLink

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
//        let gridStream = hoverController.sharedGridEvent
//        let mouseStream = input.sharedMouseDown
        
//        gridStream
//            .removeDuplicates(by: {
//                $0.latestState?.targetGrid.id == $1.latestState?.targetGrid.id
//            })
//            .sink {
//                $0.latestState?.targetGrid.showName()
//                $0.maybeLasteState?.targetGrid.hideName()
//            }
//            .store(in: &bag)
//        
//        mouseStream
//            .combineLatest(
//                glyphStream,
//                gridStream
//            )
//            .sink { _, glyphEvent, gridEvent in
//                self.lockedNodeEvent = glyphEvent
//                self.lockedGridEvent = gridEvent
//            }
//        .store(in: &bag)
        
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
            $0.instanceConstants?.addedColor += LFloat4(0.0, 0.3, 0.0, 0.0)
        }
    }
    
    func defocusGlyphState(_ nodeState: NodePickingState) {
        updateGlyphState(nodeState) {
            $0.instanceConstants?.addedColor -= LFloat4(0.0, 0.3, 0.0, 0.0)
        }
    }
    
    private func updateGlyphState(_ pickingState: NodePickingState, _ action: (GlyphNode) -> Void) {
        guard let pickedNodeSyntaxID = pickingState.parserSyntaxID
        else { return }
        
        pickingState
            .targetGrid
            .updateAssociatedNodes(
                pickedNodeSyntaxID
            ) { node, _ in
                action(node)
            }
    }
}
