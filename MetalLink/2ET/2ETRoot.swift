//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Combine
import MetalKit
import SwiftUI
import SwiftSyntaxParser
import SwiftSyntax

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    lazy var camera = DebugCamera(link: link)
    lazy var root = RootNode(camera)
    var bag = Set<AnyCancellable>()
    
    var lastID: InstanceIDType = UInt.zero
    var lastGrid: CodeGrid?
    var lastSyntaxID: SyntaxIdentifier? = nil
    
    lazy var builder = CodeGridGlyphCollectionBuilder(
        link: link,
        sharedSemanticMap: GlobalInstances.gridStore.semanticMap,
        sharedTokenCache: GlobalInstances.gridStore.tokenCache
    )
    
    init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        try setupSnapTestMulti()
        
        // TODO: ManyGrid need more abstractions
//        try setupSnapTestMonoMuchDataManyGrid()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
}

enum MetalGlyphError: String, Error {
    case noBitmaps
    case noTextures
    case noMesh
    case noAtlasTexture
}

extension TwoETimeRoot {
    func setupSnapTestMulti() throws {
        // TODO: make switching between multi/mono better
        // multi needs to add each collection; mono needs to add root
        builder.mode = .multiCollection
        
        let rootCollection = builder.getCollection()
        root.add(child: rootCollection)
        root.scale = LFloat3(0.25, 0.25, 0.25)
        root.position.z -= 30
        
        let editor = WorldGridEditor()
        
        var files = 1
        func doEditorAdd(_ childPath: URL) {
            let consumer = builder.createConsumerForNewGrid()
            consumer.targetCollection.position.z -= 30
            root.add(child: consumer.targetCollection)
            
            consumer.consume(url: childPath)
            consumer.targetGrid.fileName = childPath.fileName
        
            let nextRow: WorldGridEditor.AddStyle = .inNextRow(consumer.targetGrid)
            let nextPlane: WorldGridEditor.AddStyle = .inNextPlane(consumer.targetGrid)
            let trailing: WorldGridEditor.AddStyle = .trailingFromLastGrid(consumer.targetGrid)
            
//            let random = Bool.random() ? nextRow : Bool.random() ? nextPlane : trailing
//            editor.transformedByAdding(random)
//            editor.transformedByAdding(trailing)
            
            if files % 11 == 0 {
                editor.transformedByAdding(nextRow)
            } else if files % 51 == 0 {
                editor.transformedByAdding(nextPlane)
            } else {
                editor.transformedByAdding(trailing)
            }
            
            files += 1
            GlobalInstances.gridStore.semanticsController
                .attachPickingStream(to: consumer.targetGrid)
        }
        
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        doEditorAdd(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                doEditorAdd(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
    
    // TODO: This is going to be complicated.
    // I will try to update the SyntaxConsumer and GlyphCollection
    // to have some kind of child grid relationship.
    // Maybe a subclass of GlyphCollection that is MultiGridCollection.
    // If I do this, the child grids will have to update the parent buffer
    // somehow, without making duplicates.
    // Maybe avoiding the draw calls isn't important for now? ...
    func setupSnapTestMonoMuchDataManyGrid() throws {
        builder.mode = .monoCollection
        
        let rootCollection = builder.getCollection()
        rootCollection.scale = LFloat3(0.5, 0.5, 0.5)
        rootCollection.position.z -= 30
        root.add(child: rootCollection)
        
        let editor = WorldGridEditor()
        editor.layoutStrategy = .collection(target: rootCollection)
        
        func doEditorAdd(_ childPath: URL) {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: childPath)
            rootCollection.updateModelConstants()
            editor.transformedByAdding(.trailingFromLastGrid(consumer.targetGrid))
        }
        
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        doEditorAdd(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                doEditorAdd(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
}
