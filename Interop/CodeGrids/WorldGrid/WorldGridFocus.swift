//
//  WorldGridFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/17/22.
//

import Foundation

class WorldGridFocusController: ObservableObject {
    let link: MetalLink
    let camera: MetalLinkCamera
    let editor: WorldGridEditor
    var snapping: WorldGridSnapping { editor.snapping }
    
    @Published var state: State = .start {
        willSet { transition(from: state, to: newValue) }
    }
    
    var focusableGrids: [WorldGridSnapping.RelativeGridMapping] {
        available()
    }
    
    init(
        link: MetalLink,
        camera: MetalLinkCamera,
        editor: WorldGridEditor
    ) {
        self.link = link
        self.camera = camera
        self.editor = editor
    }
}

extension WorldGridFocusController {
    enum State {
        case start
        case set(CodeGrid)
        
        var focusedGrid: CodeGrid? {
            switch self {
            case .start:
                return nil
            case .set(let grid):
                return grid
            }
        }
    }
    
    private var cameraPosition: LFloat3 {
        get { camera.position }
        set { camera.position = newValue }
    }
    
    private func available() -> [WorldGridSnapping.RelativeGridMapping] {
        guard let focused = state.focusedGrid else {
            return []
        }
        
        return snapping.gridsRelativeTo(focused).sorted(by: { first, second in
            if first.direction < second.direction { return true }
            if first.direction > second.direction { return false }
            if first.targetGrid.fileName < second.targetGrid.fileName { return true }
            return false
        })
    }
}

private extension WorldGridFocusController {
    func transition(from lastState: State, to currentState: State) {
        switch (lastState, currentState) {
        case let (.start, .set(focus)):
            setStartGrid(focus)
        case let (.set(previus), .set(next)):
            moveBetweenGrids(previus, next)
        default:
            print("unhandled transition: \(state) -> \(currentState)")
        }
    }
    
    func setStartGrid(_ grid: CodeGrid) {
        camera.position = grid.position.translated(
            dX: grid.halfWidth,
            dZ: 150.0
        )
    }
    
    func moveBetweenGrids(_ lastGrid: CodeGrid, _ newGrid: CodeGrid) {
        camera.position = newGrid.position.translated(
            dX: newGrid.halfWidth,
            dZ: 150.0
        )
    }
}
