//
//  MetalLinkTextureLibrary.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/23/22.
//

import Foundation
import MetalKit
import Metal
import Combine

extension MetalLinkPickingTexture {
    struct Config {
        private init() { }
        static let colorIndex: Int = 1
        static let pixelFormat: MTLPixelFormat = .r32Uint
        static let clearColor: MTLClearColor = MTLClearColor(
            red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0
        )
    }
}

class MetalLinkPickingTexture: MetalLinkReader {
    let link: MetalLink
    var pickingTexture: MTLTexture?
    var generateNewTexture: Bool = false
    
    private var bag = Set<AnyCancellable>()

    init(link: MetalLink) {
        self.link = link
        self.pickingTexture = MetalLinkPickingTexture.generatePickingTexture(for: link)
        
        link.sizeSharedUpdates.sink { newSize in
            self.onSizeChanged(newSize)
        }.store(in: &bag)
        
        link.input.sharedMouseDown.sink { mouseDown in
            self.onMouseDown(mouseDown)
        }.store(in: &bag)
    }
    
    func updateDescriptor(_ target: MTLRenderPassDescriptor) {
        if generateNewTexture || detectedSizeDifference {
            pickingTexture = Self.generatePickingTexture(for: link)
            generateNewTexture = false
        }
        
        target.colorAttachments[Config.colorIndex].texture = pickingTexture
        target.colorAttachments[Config.colorIndex].loadAction = .clear
        target.colorAttachments[Config.colorIndex].storeAction = .store
        target.colorAttachments[Config.colorIndex].clearColor = Config.clearColor
    }
}

private extension MetalLinkPickingTexture {
    func onMouseDown(_ mouseDown: OSEvent) {
        let (x, y) = (mouseDown.locationInWindow.x.float, mouseDown.locationInWindow.y.float)
        
        let drawableSize = link.viewDrawableFloatSize
        let viewSize = link.viewPercentagePosition(x: x, y: y)
        let drawablePosition = (viewSize.x * drawableSize.x,
                                drawableSize.y - viewSize.y * drawableSize.y)
        
        let origin = MTLOrigin(x: Int(drawablePosition.0), y: Int(drawablePosition.1), z: 0)
        doPickingTextureBlitRead(at: origin)
    }
    
    func doPickingTextureBlitRead(at sourceOrigin: MTLOrigin) {
        guard let pickingTexture = pickingTexture,
              let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
              let pickBuffer = link.device.makeBuffer(length: IDType.memStride) else {
            return
        }
        commandBuffer.label = "PickingBuffer"
        blitEncoder.label = "PickingEncoder"
        commandBuffer.addCompletedHandler { buffer in
            self.onPickBlitComplete(pickBuffer)
        }
        
        let sourceSize = MTLSize(width: 1, height: 1, depth: 1)
        
        blitEncoder.copy(
            from: pickingTexture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: sourceOrigin,
            sourceSize: sourceSize,
            to: pickBuffer,
            destinationOffset: 0,
            destinationBytesPerRow: IDType.memStride,
            destinationBytesPerImage: IDType.memStride
        )
        
        blitEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    func onPickBlitComplete(_ pickBuffer: MTLBuffer) {
        print("\nPick complete")
        let pointer = pickBuffer.contents().bindMemory(to: UInt.self, capacity: 1)
        print(pointer.pointee)
        print("--------------------------------------\n")
    }
}

private extension MetalLinkPickingTexture {
    private var detectedSizeDifference: Bool {
        guard let pickingTexture = pickingTexture else {
            return false
        }
        
        let (viewWidth, viewHeight) = (viewDrawableRoundSize.x, viewDrawableRoundSize.y)
        let (pickingWidth, pickingHeight) = (pickingTexture.width, pickingTexture.height)
        let didFindSizeChange = viewWidth != pickingWidth || viewHeight != pickingHeight
        if didFindSizeChange {
            print("Detected new sizes:")
            print("view   : \(viewWidth), \(viewHeight)")
            print("texture: \(pickingWidth), \(pickingHeight)")
        }
        return didFindSizeChange
    }
    
    private func onSizeChanged(_ newSize: CGSize) {
        print("New size reported: \(newSize)")
        generateNewTexture = true
    }
}

enum PickingTextureError: Error {
    case noTextureAvailable
}

extension MetalLinkPickingTexture {
    static func generatePickingTexture(for link: MetalLink) -> MTLTexture? {
        let drawableSize = link.viewDrawableRoundSize
        print("Generating new picking texture: \(drawableSize)")
        
        let descriptor = MTLTextureDescriptor()
        descriptor.width = drawableSize.x
        descriptor.height = drawableSize.y
        descriptor.pixelFormat = Config.pixelFormat
        descriptor.storageMode = .private
        descriptor.usage = .renderTarget
        
        do {
            guard let pickingTexture = link.device.makeTexture(descriptor: descriptor)
            else { throw PickingTextureError.noTextureAvailable }
            return pickingTexture
        } catch {
            print(error)
            return nil
        }
    }
}
