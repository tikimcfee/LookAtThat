//
//  MetalLinkInstancedObject+State.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import Metal

extension MetalLinkInstancedObject {
    class InstanceState {
        let link: MetalLink
        
        private(set) var bufferCache: Cached<MTLBuffer?>
        var nodes: [InstancedNodeType] = [] { didSet { bufferCache.dirty() } }
        var constants: [InstancedConstants] = [] { didSet { bufferCache.dirty() } }
        
        init(link: MetalLink) {
            self.link = link
            self.bufferCache = Cached(current: nil, update: { nil })
            self.bufferCache.update = makeBuffer
        }
        
        // Appends info and returns last index
        func appendToState(
            node newNode: InstancedNodeType,
            constants newConstants: InstancedConstants
        ) -> Int {
            nodes.append(newNode)
            constants.append(newConstants)
            return constants.endIndex - 1
        }
        
        open func onNodeAdded(
            _ newNode: InstancedNodeType,
            _ newConstants: InstancedConstants,
            at index: Int
        ) {
            // override to update node meta et al.
            // so dirty.. I don't like this, but I'm just in a mood today.
            // I really just want to make things work because I need a win.
            // Code can be a diary, did you know that? =)
        }
        
        typealias BufferOperator = (
            InstancedNodeType,
            InstancedConstants,
            UnsafeMutablePointer<InstancedConstants>
        ) -> Void
        
        func zipUpdate(_ nodeUpdateFunction: BufferOperator)  {
            guard bufferCache.willRebuild else {
                return
            }
            
            guard var pointer = getConstantsPointer() else {
                return
            }
            
            zip(nodes, constants).forEach { node, constant in
                nodeUpdateFunction(node, constant, pointer)
                pointer = pointer.advanced(by: 1)
            }
        }
        
        func getConstantsPointer() -> UnsafeMutablePointer<InstancedConstants>? {
            bufferCache.get()?
                .boundPointer(as: InstancedConstants.self, count: constants.count)
        }
        
        private func makeBuffer() -> MTLBuffer? {
            print("Creating buffer for instanced constants: \(self.constants.count)")
            do {
                if self.constants.count == 0 {
                    print("\n\n\tAttempting to create empty buffer!")
                }
                let safeCount = max(1, self.constants.count)
                return try link.makeBuffer(of: InstancedConstants.self, count: safeCount)
            } catch {
                print(error)
                return nil
            }
        }
    }
}
