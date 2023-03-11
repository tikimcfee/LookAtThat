//
//  2ETTests.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 1/28/23.
//

import Combine
import MetalKit
import SwiftUI
import SwiftParser
import SwiftSyntax

extension TwoETimeRoot {
    func setupTriangleStripTest() throws {
        root.position.z -= 10
        
        let startQuad = BackgroundQuad(link)
        startQuad.position.translateBy(dX: -50)
        startQuad.setColor(LFloat4(1.0, 0.0, 0.0, 1.0))
        root.add(child: startQuad)
        
        let midQuad = BackgroundQuad(link)
        startQuad.position.translateBy(dY: -50, dZ: 50)
        startQuad.setColor(LFloat4(0.0, 1.0, 0.0, 1.0))
        root.add(child: midQuad)
        
        let endQuad = BackgroundQuad(link)
        endQuad.setColor(LFloat4(0.0, 0.0, 1.0, 1.0))
        endQuad.position.translateBy(dX: 50, dY: -10, dZ: -50)
        root.add(child: endQuad)
        
        let farquad = BackgroundQuad(link)
        farquad.setColor(LFloat4(0.0, 0.2, 0.2, 1.0))
        farquad.position.translateBy(dX: 25, dY: -30, dZ: -100)
        root.add(child: farquad)
        
        let strip = MetalLinkLine(link)
        strip.setColor(LFloat4(1.0, 0.0, 0.5, 1.0))
        root.add(child: strip)
        
        strip.appendSegment(about: startQuad.position)
        strip.appendSegment(about: midQuad.position)
        strip.appendSegment(about: endQuad.position)
        
        var nodeToggle = true
        var nextNode: MetalLinkNode { nodeToggle ? startQuad : farquad }
        
        var first = true
        QuickLooper(interval: .milliseconds(200)) {
            if !first { strip.popSegment() }
            strip.appendSegment(about: nextNode.position)
            
            nodeToggle.toggle()
            first = false
        }.runUntil { false }
    }
}


// MARK: - Not Current Tests

extension TwoETimeRoot {
    func setupSnapTestMulti() throws {
        builder.mode = .multiCollection
        root.add(child: GlobalInstances.gridStore.traceLayoutController.currentTraceLine)
        
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
            
            plan.startRender {
                // TODO: Bounds... WHY MORE BOUNDS
                // IT'S ALWAYS BOUNDS! !@(#*!@)(#*)!
                // Parent rects aren't invalidated when children change.
                // Just.. just clear everything and move on. Figure out
                // bounds.. AGAIN.. later.
                BoundsCaching.ClearRoot(self.root)
                plan.targetParent.position = LFloat3(
                    -plan.targetParent.boundsCenterWidth,
                     0,
                     0
                )
                
                self.root.add(child: plan.targetParent)
                //                var counter = 0.1
                //                QuickLooper(interval: .milliseconds(16)) {
                //                    plan.targetParent.scale = LFloat3(repeating: cos(counter.float / 10.float))
                //                    counter += 0.1
                //                }.runUntil { false }
            }
        }
    }
    
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
}

// MARK: - Test load pipeline

extension TwoETimeRoot {
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
