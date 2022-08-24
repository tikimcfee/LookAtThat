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

enum PickingTextureError: Error {
    case noTextureAvailable
}

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
