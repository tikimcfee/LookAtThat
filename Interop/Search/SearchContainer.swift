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
    }
    
    private let searchQueue = DispatchQueue(label: "GridTextSearch", qos: .userInitiated)
    private var currentRenderTask: RenderTask?
    
    private let gridCache: GridCache
    var mode: Mode = .inPlace
    
    init(gridCache: GridCache) {
        self.gridCache = gridCache
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
            newInput: newInput,
            gridCache: gridCache,
            mode: mode,
            onComplete: completion
        )
        
        currentRenderTask?.task.cancel()
        currentRenderTask?.task = renderTask.task
        searchQueue.async(execute: renderTask.task)
    }
}
