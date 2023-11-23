//
//  SearchRenderTask.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 7/12/22.
//

import Foundation
import SwiftSyntax
import MetalLink
import BitHandling

class SearchFocusRenderTask {
    typealias SearchReceiver = (
        _ source: CodeGrid,
        _ semantics: Set<SemanticInfo>
    ) throws -> Void
    
    typealias NegativeReceiver = (
        _ source: CodeGrid
    ) throws -> Void
    
    private let newInput: String
    private let gridCache: GridCache
    private let mode: SearchContainer.Mode
    private let onComplete: (SearchFocusRenderTask) -> Void
    lazy var task = DispatchWorkItem(block: sharedDispatchBlock)
    
    private static let _stopwatch = Stopwatch()
    private var stopwatch: Stopwatch { Self._stopwatch }
    
    var searchLayout = ConcurrentArray<CodeGrid>()
    var missedGrids = ConcurrentArray<CodeGrid>()
    
    init(
        newInput: String,
        gridCache: GridCache,
        mode: SearchContainer.Mode,
        onComplete: @escaping (SearchFocusRenderTask) -> Void
    ) {
        self.newInput = newInput
        self.gridCache = gridCache
        self.mode = mode
        self.onComplete = onComplete
    }
}

private extension SearchFocusRenderTask {
    func sharedDispatchBlock() -> Void {
        stopwatch.start()
        do {
            try doSearch()
        } catch {
            print(error)
        }
        stopwatch.stop()
        print("-- Search finished, \(stopwatch.elapsedTimeString())")
        stopwatch.reset()
        
        onComplete(self)
    }
    
    func doSearch() throws {
        printStart(newInput)
        resetAllGridFocusLevels()
        kickoffGridWalks()
        sortFocusResults()
        printStop(newInput + " ++ end of call")
    }
    
    func resetAllGridFocusLevels() {
        var gridWork = gridCache.cachedGrids.values.makeIterator()
        let workGroup = DispatchGroup()
        while !task.isCancelled, let next = gridWork.next() {
            workGroup.enter()
            WorkerPool.shared.nextWorker().async {
                defer { workGroup.leave() }
                next.gridBackground.setColor(LFloat4(0.0, 0.0, 0.0, 1.0))
                next.rootNode.scale = LFloat3(1, 1, 1)
                
                next.updateAllNodeConstants { node, stopFlag in
                    node.instanceConstants?.addedColor = .zero
                    node.instanceConstants?.modelMatrix.columns.3.z = 1.0
                    if self.task.isCancelled {
                        stopFlag = true
                    }
                }
            }
        }
        workGroup.wait()
    }
    
    func sortFocusResults() {
        func sizeSort(_ left: CodeGrid, _ right: CodeGrid) -> Bool {
            if left.lengthY < right.lengthY { return true }
            if left.lengthX < right.lengthX { return true }
            return false
        }
        searchLayout.directWriteAccess {
            $0 = $0.sorted(by: sizeSort(_:_:))
        }
        missedGrids.directWriteAccess {
            $0 = $0.sorted(by: sizeSort(_:_:))
        }
    }
    
    func kickoffGridWalks() {
        guard !newInput.isEmpty else {
            gridCache.cachedGrids.values.forEach {
                missedGrids.append($0)
            }
            return
        }
        
        var gridWork = gridCache.cachedGrids.values.makeIterator()
        let workGroup = DispatchGroup()
        let searchText = newInput
        while !task.isCancelled, let next = gridWork.next() {
            workGroup.enter()
            WorkerPool.shared.nextWorker().async {
                try? self.test(grid: next, searchText: searchText)
                workGroup.leave()
            }
        }
        workGroup.wait()
    }
    
    func test(grid: CodeGrid, searchText: String) throws {
        guard !(grid.sourcePath?.isDirectory ?? false) else { return }
        
        var matched: [SemanticInfo: Int] = [:]
        
        for (_, info) in grid.semanticInfoMap.semanticsLookupBySyntaxId {
            try self.throwIfCancelled()
            
            var matchesReference: Bool {
                info.referenceName
                    .containsMatch(searchText, caseSensitive: false)
            }
            
            var matchesTrivia: Bool {
                info.node.trailingTrivia.stringified.containsMatch(searchText, caseSensitive: false)
                || info.node.leadingTrivia.stringified.containsMatch(searchText, caseSensitive: false)
            }
            
            if matchesReference || matchesTrivia {
                matched[info, default: 0] += 1
            }
        }
        
        if matched.count > 0 {
            for (info, _) in matched {
                try focusNodesForSemanticInfo(source: grid, info.syntaxId)
            }
            searchLayout.append(grid)
        } else {
            try defocusNodesForSemanticInfo(source: grid)
            missedGrids.append(grid)
        }
    }
}

// MARK: - Default Highlighting

private extension SearchFocusRenderTask {
    var focusAddition: LFloat4 { LFloat4(0.04, 0.08, 0.12, 0.0) }
    var matchAddition: LFloat4 { LFloat4(0.20, 0.00, 0.00, 0.0) }
    var focusPosition: LFloat3 { LFloat3(0.0, 0.0, 1.5) }
    
    func focusNodesForSemanticInfo(
        source: CodeGrid,
        _ matchingSemanticInfo: SyntaxIdentifier
    ) throws {
        try source.semanticInfoMap.walkFlattened(
            from: matchingSemanticInfo,
            in: source.tokenCache
        ) { info, targetNodes in
            for node in targetNodes {
                try self.throwIfCancelled()
                if info.syntaxId == matchingSemanticInfo {
                    node.instanceConstants?.addedColor += self.matchAddition
                } else {
                    node.instanceConstants?.addedColor += self.focusAddition
                }
                node.instanceConstants?.modelMatrix.translate(vector: self.focusPosition)
            }
        }
    }
    
    func defocusNodesForSemanticInfo(source: CodeGrid) throws {
        let clearFocus = newInput.isEmpty
        source.rootNode.scale = LFloat3(0.4, 0.4, 0.4)
        source.gridBackground.setColor(LFloat4(0.2, 0.2, 0.2, 1))
        for rootNode in source.consumedRootSyntaxNodes {
            try source.semanticInfoMap.walkFlattened(
                from: rootNode.id,
                in: source.tokenCache
            ) { info, targetNodes in
                for node in targetNodes {
                    try self.throwIfCancelled()
                    if clearFocus {
                        node.instanceConstants?.addedColor = .zero
                    } else {
                        node.instanceConstants?.addedColor -= self.focusAddition
                    }
                    node.position.z = 1
                }
            }
        }
    }
}

extension SearchFocusRenderTask {
    @inlinable
    public func throwIfCancelled() throws {
        if task.isCancelled { throw Condition.cancelled(input: newInput) }
    }
}

private extension SearchFocusRenderTask {
    func printStart(_ input: String) {
        print("new search ---------------------- [\(input)]")
    }
    
    func printStop(_ input: String) {
        print("---------------------- [\(input)] finished ")
    }
    
    func printCancelled(_ input: String) {
        print("XXXXXXXXXXX >> [\(input)] Cancelled")
    }
}

private enum Condition: Error {
    case cancelled(input: String)
}
