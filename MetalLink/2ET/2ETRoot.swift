//
//  2ETRoot.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//
//  - With thanks to Rick Twohy
//  https://discord.gg/hKPBTbC
//

import Combine
import MetalKit
import SwiftUI
import SwiftSyntaxParser
import SwiftSyntax

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    var bag = Set<AnyCancellable>()
    
    lazy var root = RootNode(camera)
    
    lazy var builder = try! CodeGridGlyphCollectionBuilder(
        link: link,
        sharedSemanticMap: GlobalInstances.gridStore.semanticMap,
        sharedTokenCache: GlobalInstances.gridStore.tokenCache,
        sharedGridCache: GlobalInstances.gridStore.gridCache
    )
    
    var camera: DebugCamera {
        GlobalInstances.debugCamera
    }
    
    var editor: WorldGridEditor {
        GlobalInstances.gridStore.editor
    }
    
    var focus: WorldGridFocusController {
        GlobalInstances.gridStore.worldFocusController
    }
    
    init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        camera.interceptor.onNewFileOperation = handleDirectory
        camera.interceptor.onNewFocusChange = handleFocus
        
//        try setupNodeChildTest()
//        try setupNodeBackgroundTest()
//        try setupBackgroundTest()
        try setupSnapTestMulti()
        
         // TODO: ManyGrid need more abstractions
//        try setupSnapTestMonoMuchDataManyGrid()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Create a proper container for all this glyph parent stuff.
        // Collection, builder, consumer, writer, grid... lol.
        // One more can't hurt.
        sdp.renderCommandEncoder.setVertexBuffer(builder.parentBuffer.buffer, offset: 0, index: 3)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
    
    func handleFocus(_ direction: SelfRelativeDirection) {
        let focused = editor.lastFocusedGrid
        guard let current = focused else { return }
        
        let grids = editor.snapping.gridsRelativeTo(current, direction)
        
        if let first = grids.first {
            focus.state = .set(first.targetGrid)
        } else {
            focus.state = .set(current)
        }
    }
    
    func handleDirectory(_ file: FileOperation) {
        switch file {
        case .openDirectory:
            openDirectory { file in
                guard let url = file.parent else { return }
                GlobalInstances.fileBrowser.setRootScope(url)
            }
        }
    }
    
    func basicGridPipeline(_ childPath: URL) -> GlyphCollectionSyntaxConsumer {
        let consumer = builder.createConsumerForNewGrid()
        consumer.consume(url: childPath)
        consumer.targetGrid.fileName = childPath.fileName
        
        GlobalInstances.gridStore.nodeHoverController
            .attachPickingStream(to: consumer.targetGrid)
        
        return consumer
    }
    
    func basicAddPipeline(_ action: @escaping (URL) -> Void) {
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        action(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                action(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
    
    func directoryAddPipeline(_ action: @escaping (URL) -> Void) {
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                action(rootPath)
                
            case let .newSingleCommand(url, _):
                action(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
}

// MARK: - Current Test

extension TwoETimeRoot {
    func setupSnapTestMulti() throws {
        builder.mode = .multiCollection
        
        directoryAddPipeline { filePath in
           let plan = RenderPlan(
                rootPath: filePath,
                queue: DispatchQueue.global(),
                builder: self.builder,
                editor: self.editor,
                focus: self.focus,
                hoverController: GlobalInstances.gridStore.nodeHoverController,
                mode: .cacheAndLayout
            )
            
//            var counter = 0.1
            plan.startRender {
                self.root.add(child: plan.targetParent)
                let edge = plan.targetParent.trailing
                let top = plan.targetParent.top
                self.camera.position = LFloat3(edge / 2.0, top + 128.0, edge)
                self.camera.rotation = LFloat3(Float.pi / 4.0, 0, 0)
//                QuickLooper(interval: .milliseconds(30)) {
//                    plan.targetParent.rotation.x += 0.1
//                    counter += 0.1
//                }.runUntil { false }
            }
        }
    }
}


// MARK: - Not Current Tests

extension TwoETimeRoot {
    func setupNodeChildTest() throws {
        let origin = BackgroundQuad(link)
        origin.quadSize = .init(1, 1)
        origin.setColor(LFloat4(1, 0, 0, 1))
        
        let firstparent = BackgroundQuad(link)
        firstparent.quadSize = .init(1, 1)
        firstparent.setColor(LFloat4(0, 1, 0, 1))
        
        let firstChild = BackgroundQuad(link)
        firstChild.quadSize = .init(1, 1)
        firstChild.setColor(LFloat4(0, 0, 1, 1))
        
        root.add(child: origin)
        origin.add(child: firstparent)
        firstparent.add(child: firstChild)
        
        firstparent.position = LFloat3(2, 0, -1)
        firstChild.position = LFloat3(2, 0, 0)
        
        var counter = 0.1
        QuickLooper(interval: .milliseconds(30)) {
            firstparent.position.x = cos(counter).float
            firstparent.scale = LFloat3(cos(counter).float, 1, 1)
            counter += 0.1
        }.runUntil { false }
    }
    
    func setupNodeBackgroundTest() throws {
        builder.mode = .multiCollection // TODO: DO NOT switch to mono without render breakpoints. crazy memory leak / performance issue with many grids
        
        func doAdd(_ consumer: GlyphCollectionSyntaxConsumer) {
            root.add(child: consumer.targetCollection)
            editor.transformedByAdding(.trailingFromLastGrid(consumer.targetGrid))

//            // TODO: < 30ms updates gives us flickering because of.. rendering order maybe?
//            QuickLooper(interval: .milliseconds(30)) {
//                consumer.targetCollection.rotation.y += 0.1
//            }.runUntil { false }
            
            GlobalInstances.gridStore.nodeHoverController
                .attachPickingStream(to: consumer.targetGrid)
        }
        
        basicAddPipeline { filePath in
//            WorkerPool.shared.nextWorker().async {
                doAdd(self.basicGridPipeline(filePath))
//            }
            
        }
    }
    
    func setupBackgroundTest() throws {
        let background = BackgroundQuad(link)
        background.position = LFloat3(0.0, 0.0, -50.0)
        background.setColor(LFloat4(1.0, 0.0, 0.0, 1.0))
        background.quadSize = .init(1.0, 3.0)
        
        let background2 = BackgroundQuad(link)
        background2.position = LFloat3(4.0, 0.0, -50.0)
        background2.setColor(LFloat4(0.0, 1.0, 0.0, 1.0))
        background2.quadSize = .init(1.0, 7.0)
        
        let background3 = BackgroundQuad(link)
        background3.position = LFloat3(8.0, 0.0, -50.0)
        background3.setColor(LFloat4(0.0, 0.0, 1.0, 1.0))
        
        print(background.centerPosition)
        print(background2.centerPosition)
        print(background3.centerPosition)
        
        root.add(child: background)
        root.add(child: background2)
        root.add(child: background3)
        
        background2.setLeading(background.localTrailing)
        background2.setTop(background.localTop)
        background3.setLeading(background2.localTrailing)
        background3.setTop(background2.localTop)
        
        print(background.centerPosition)
        print(background2.centerPosition)
        print(background3.centerPosition)
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
        
        editor.layoutStrategy = .collection(target: rootCollection)
        
        var isFirst = true
        func doEditorAdd(_ childPath: URL) {
            let consumer = builder.createConsumerForNewGrid()
            consumer.consume(url: childPath)
            
            editor.transformedByAdding(.trailingFromLastGrid(consumer.targetGrid))
            guard isFirst else { return }
            isFirst = false
            
            var time = Float(0.0)
            func testAnimation() {
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(30)) {
                    time += 30
                    consumer.targetGrid.position += LFloat3(cos(time / 1000), 0, 0)
                    testAnimation()
                }
            }
            testAnimation()
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
