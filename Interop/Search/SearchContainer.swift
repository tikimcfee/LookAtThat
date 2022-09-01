//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation

class SearchContainer {
    enum Mode {
        case inPlace
        case focusBox
    }
    
    private let searchQueue = DispatchQueue(label: "GridTextSearch", qos: .userInitiated)
    private var currentRenderTask: RenderTask?
    
    var codeGridParser: CodeGridParser
    var mode: Mode = .inPlace
    
    init(codeGridParser: CodeGridParser) {
        self.codeGridParser = codeGridParser
    }
        
    func search(
        _ newInput: String,
        _ completion: @escaping () -> Void
    ) {
        if currentRenderTask == nil && newInput.isEmpty {
            print("Skipping search; input empty, nothing to reset")
            return
        }
        
        let renderTask = RenderTask(
            codeGridParser: codeGridParser,
            newInput: newInput,
            mode: mode,
            onComplete: completion
        )
        
        currentRenderTask?.task.cancel()
        currentRenderTask?.task = renderTask.task
        searchQueue.async(execute: renderTask.task)
    }
}
