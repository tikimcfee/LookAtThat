//
//  SearchContainer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation
import SceneKit

class SearchContainer {
    private enum Condition: Error {
        case cancelled(input: String)
    }
    
    private let searchQueue = DispatchQueue(label: "GridTextSearch", qos: .userInitiated)
    private var currentWorkItem = DispatchWorkItem { }
    
    var hovers = TokenHoverInteractionTracker()
    var codeGridFocus: CodeGridFocusController
    var codeGridParser: CodeGridParser
    
    init(codeGridParser: CodeGridParser,
         codeGridFocus: CodeGridFocusController) {
        self.codeGridParser = codeGridParser
        self.codeGridFocus = codeGridFocus
    }
    
    func createNewSearchFocus(_ state: SceneState) {
        print("creating new search focus")
        codeGridFocus.setNewFocus()
    }
        
    func search(_ newInput: String, _ state: SceneState) {
        setupNewSearch(newInput, state)
    }
    
    private func setupNewSearch(_ newInput: String, _ state: SceneState) {
        func searchBlock() {
            do {
                try doSearch(task: currentWorkItem, newInput, state)
            } catch {
                print(error)
            }
        }
        currentWorkItem.cancel()
        currentWorkItem = DispatchWorkItem(block: searchBlock)
        searchQueue.async(execute: currentWorkItem)
    }
    
    private func doSearch(task: DispatchWorkItem, _ newInput: String, _ state: SceneState) throws {
        printStart(newInput)
        func throwIfCancelled() throws {
            if task.isCancelled { throw Condition.cancelled(input: newInput) }
        }
        
        var toAdd: [CodeGrid] = []
        var toRemove: [CodeGrid] = []
        var toHover: Set<SCNNode> = []
        
        // Start search
        codeGridParser.query.walkGridsForSearch(
            newInput,
            onPositive: { foundInGrid, leafInfo in
                try throwIfCancelled()
                
                // Found new grid to add to focus
                toAdd.append(foundInGrid)
                
                // Collect all nodes from all semantic info that contributed to passed test
                try leafInfo.forEach { info in
                    try foundInGrid.codeGridSemanticInfo.forAllNodesAssociatedWith(
                        info.syntaxId,
                        codeGridParser.tokenCache
                    ) { info, nodes in
                        try throwIfCancelled()
                        
                        toHover.formUnion(nodes)
                    }
                }
            },
            onNegative: { excludedGrid, leafInfo in
                try throwIfCancelled()
                
                // This grid did not pass; remove from focus
                toRemove.append(excludedGrid)
            }
        )
        
        // Add / remove grids, and set new highlighted nodes
        let displayMode = toAdd.count > 5
            ? CodeGrid.DisplayMode.all
            : CodeGrid.DisplayMode.glyphs
        
        try toRemove.forEach {
            try throwIfCancelled()
            
            $0.displayMode = .all
            codeGridFocus.removeGridFromFocus($0)
        }
        try toAdd.enumerated().forEach {
            try throwIfCancelled()
            
            $0.element.displayMode = displayMode
            codeGridFocus.addGridToFocus($0.element, $0.offset)
        }
        
        let (toFocus, toUnfocus) = hovers.diff(toHover)
        try toUnfocus.forEach {
            try throwIfCancelled()
            hovers.unfocusNode($0)
        }
        try toFocus.forEach {
            try throwIfCancelled()
            hovers.focusNode($0)
        }
        
        printStop(newInput)
    }
    
    private func printStart(_ input: String) {
        print("new search ---------------------- [\(input)]")
    }
    
    private func printStop(_ input: String) {
        print("---------------------- [\(input)] finished ")
    }
    
    private func printCancelled(_ input: String) {
        print("XXXXXXXXXXX >> [\(input)] Cancelled")
    }
}
