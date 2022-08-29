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
        
        func appendToState(node: InstancedNodeType, constants: InstancedConstants) {
            self.nodes.append(node)
            self.constants.append(constants)
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
