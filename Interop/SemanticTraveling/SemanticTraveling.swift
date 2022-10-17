//
//  LinkLanguageServer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/16/22.
//

import Foundation
import Combine

class SemanticTravelling {
    var bag = Set<AnyCancellable>()
    
    private var lastState: NodePickingState?
    private var lockedState: NodePickingState?
    
    func test() {
        GlobalInstances
            .gridStore
            .nodeHoverController
            .$lastGlyphState
            .sink(receiveValue: { self.handleHoverState($0) })
            .store(in: &bag)
        
        GlobalInstances
            .defaultLink
            .input
            .sharedMouseDown
            .sink(receiveValue: { _ in self.handleMouseDown() })
            .store(in: &bag)
    }
    
    func handleHoverState(_ state: NodePickingState?) {
        guard lockedState == nil else { return }
        guard let state = state else { return }
        lastState = state
    }
    
    func handleMouseDown() {
        if let lastState = lastState {
            lockedState = lastState
        }
    }
}
