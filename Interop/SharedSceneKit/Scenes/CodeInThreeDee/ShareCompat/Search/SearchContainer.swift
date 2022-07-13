//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation
import SceneKit

class SearchContainer {
    enum Mode {
        case inPlace
        case focusBox
    }
    
    private let searchQueue = DispatchQueue(label: "GridTextSearch", qos: .userInitiated)
    private var currentRenderTask: RenderTask?
    
    var hovers = TokenHoverInteractionTracker()
    var codeGridFocus: CodeGridFocusController
    var codeGridParser: CodeGridParser
    var mode: Mode = .inPlace
    
    lazy var focusControls = FocusControls(container: self)
    
    init(codeGridParser: CodeGridParser,
         codeGridFocus: CodeGridFocusController) {
        self.codeGridParser = codeGridParser
        self.codeGridFocus = codeGridFocus
    }
        
    func search(
        _ newInput: String,
        _ state: SceneState,
        _ completion: @escaping () -> Void
    ) {
        if currentRenderTask == nil && newInput.isEmpty {
            print("Skipping search; input empty, nothing to reset")
            return
        }
        
        let renderTask = RenderTask(
            codeGridFocus: codeGridFocus,
            codeGridParser: codeGridParser,
            newInput: newInput,
            state: state,
            mode: mode,
            onComplete: completion
        )
        
        currentRenderTask?.task.cancel()
        currentRenderTask?.task = renderTask.task
        searchQueue.async(execute: renderTask.task)
    }
}

extension SearchContainer {
    struct InlineControls {
        var container: SearchContainer
    }
}

extension SearchContainer {
    struct FocusControls {
        var container: SearchContainer
        
        func createNewSearchFocus(_ state: SceneState) {
            print("creating new search focus")
            container.codeGridFocus.setNewFocus()
        }
    }
}
