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
        
        private(set) var parentCache = Cached<MTLBuffer?>(current: nil, update: { nil })
        private(set) var bufferCache = Cached<MTLBuffer?>(current: nil, update: { nil })
        
        var virtualParents: [MetalLinkNode] = [] { didSet { parentCache.dirty() }}
        var nodes: [InstancedNodeType] = [] { didSet { bufferCache.dirty() } }
        var constants: [InstancedConstants] = [] { didSet { bufferCache.dirty() } }
        
        init(link: MetalLink) {
            self.link = link
            
            self.bufferCache.update = makeInstancesBuffer
            self.parentCache.update = makeParentsBuffer
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
        
        private func makeParentsBuffer() -> MTLBuffer? {
            print("Creating buffer for parent constants: \(self.virtualParents.count)")
            do {
                if self.virtualParents.count == 0 {
                    print("\n\n\tAttempting to create empty buffer!")
                }
                let safeCount = max(1, self.virtualParents.count)
                return try link.makeBuffer(of: ParentConstants.self, count: safeCount)
            } catch {
                print(error)
                return nil
            }
        }
        
        private func makeInstancesBuffer() -> MTLBuffer? {
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
