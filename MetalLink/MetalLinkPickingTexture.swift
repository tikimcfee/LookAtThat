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
    
    var currentHover: InstanceIDType = .zero {
        didSet { pickingHover.send(currentHover) }
    }
    private let pickingHover = PassthroughSubject<InstanceIDType, Never>()
    lazy var sharedPickingHover = pickingHover.share()
    
    private var bag = Set<AnyCancellable>()
    var colorIndex: Int

    init(link: MetalLink, colorIndex: Int) {
        self.link = link
        self.pickingTexture = MetalLinkPickingTexture.generatePickingTexture(for: link)
        self.colorIndex = colorIndex
        
        link.sizeSharedUpdates.sink { newSize in
            self.onSizeChanged(newSize)
        }.store(in: &bag)
        
        link.input.sharedMouse.sink { mouseMove in
            self.onMouseMove(mouseMove)
        }.store(in: &bag)
    }
    
    func updateDescriptor(_ target: MTLRenderPassDescriptor) {
        if generateNewTexture {
            pickingTexture = Self.generatePickingTexture(for: link)
            generateNewTexture = false
        }
        
        // TODO: Make better usage of clear color + constants for picking
        // .clear load action to sure *everything* is reset on the draw.
        // If not (.dontCare), the hover itself will work when directly over a node,
        // but outside values give spurious values - likely because of choice of clear color.
        target.colorAttachments[colorIndex].texture = pickingTexture
        target.colorAttachments[colorIndex].loadAction = .clear
        target.colorAttachments[colorIndex].storeAction = .store
        target.colorAttachments[colorIndex].clearColor = Config.clearColor
    }
}

private extension MetalLinkPickingTexture {
    func onMouseMove(_ mouseMove: OSEvent) {
        let (x, y) = (mouseMove.locationInWindow.x.float,
                      mouseMove.locationInWindow.y.float)
        let position = convertToDrawablePosition(windowX: x, windowY: y)
        let origin = MTLOrigin(x: Int(position.x), y: Int(position.y), z: 0)
        doPickingTextureBlitRead(at: origin)
    }
    
    func doPickingTextureBlitRead(at sourceOrigin: MTLOrigin) {
        guard sourceOrigin.x >= 0 && sourceOrigin.y >= 0 else { return }
        
        guard let pickingTexture = pickingTexture,
              let commandBuffer = link.commandQueue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
              let pickBuffer = link.device.makeBuffer(length: InstanceIDType.memStride) else {
            return
        }
        
        defer {
            blitEncoder.endEncoding()
            commandBuffer.commit()
        }
        
        guard sourceOrigin.simd2DSize < pickingTexture.simdSize else {
            print("Source origin is out of bounds: \(sourceOrigin.simd2DSize)")
            return
        }
        
        commandBuffer.label = "PickingBuffer:\(sourceOrigin.x):\(sourceOrigin.y)"
        blitEncoder.label = "PickingEncoder:\(sourceOrigin.x):\(sourceOrigin.y)"
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
            destinationBytesPerRow: InstanceIDType.memStride,
            destinationBytesPerImage: InstanceIDType.memStride
        )
    }
    
    func onPickBlitComplete(_ pickBuffer: MTLBuffer) {
        let pointer = pickBuffer.boundPointer(as: InstanceIDType.self, count: 1)
//        print("--------------------------------------\n")
//        print("\nPick complete, found: \(pointer.pointee)")
//        print("--------------------------------------\n")
        guard pointer.pointee >= InstanceCounter.startingGeneratedID else { return }
        currentHover = pointer.pointee
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
        guard drawableSize.x > 0 && drawableSize.y > 0 else {
            print("Invalid drawable size: \(drawableSize)")
            return nil
        }
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

extension LFloat2: Comparable {
    public static func < (lhs: SIMD2<Scalar>, rhs: SIMD2<Scalar>) -> Bool {
        return lhs.x < rhs.x
            && lhs.y < rhs.y
    }
}

extension MTLOrigin {
    var simd2DSize: LFloat2 {
        LFloat2(x.float, y.float)
    }
}
