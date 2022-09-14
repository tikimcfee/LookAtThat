//
//  BackingBuffer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/13/22.
//

import Metal

protocol BackingIndexed {
    var bufferIndex: UInt { get set }
    mutating func reset()
}

extension BackingIndexed {
    var arrayIndex: Int { Int(bufferIndex) }
}

class BackingBuffer<Stored: MemoryLayoutSizable & BackingIndexed> {
    let link: MetalLink
    private(set) var buffer: MTLBuffer
    var pointer: UnsafeMutablePointer<Stored>
    
    let enlargeMultiplier = 2
    private(set) var currentBufferSize = 5000
    private(set) var currentEndIndex = 0
    private var shouldRebuild: Bool {
        currentEndIndex == currentBufferSize
    }
    private var enlargeSemaphore = DispatchSemaphore(value: 1)
    
    init(link: MetalLink) throws {
        self.link = link
        let buffer = try link.makeBuffer(of: Stored.self, count: currentBufferSize)
        self.buffer = buffer
        self.pointer = buffer.boundPointer(as: Stored.self, count: currentBufferSize)
    }
    
    func createNext(_ withUpdates: ((inout Stored) -> Void)? = nil) throws -> Stored {
        if shouldRebuild { try enlargeBuffer() }
        
        var next = pointer[currentEndIndex]
        next.reset() // Memory is unitialized; call reset to clean up
        
        next.bufferIndex = UInt(currentEndIndex)
        withUpdates?(&next)
        
        pointer[currentEndIndex] = next
        
        currentEndIndex += 1
        return next
    }
    
    func enlargeBuffer() throws {
        enlargeSemaphore.wait()
        defer { enlargeSemaphore.signal() }
        guard shouldRebuild else {
            print("Already enlarged by another consumer; breaking")
            return
        }
        
        let oldSize = currentBufferSize
        let nextSize = currentBufferSize * enlargeMultiplier
        print("Enlarging buffer for '\(Stored.self)': \(currentBufferSize) -> \(nextSize)")
        currentBufferSize = nextSize
        
        let copy = pointer
        buffer = try link.copyBuffer(
            from: copy,
            oldCount: oldSize,
            newCount: nextSize
        )
        
        pointer = buffer.boundPointer(as: Stored.self, count: nextSize)
    }
}

extension BackingBuffer: RandomAccessCollection {
    subscript(position: Int) -> Stored {
        get { pointer[position] }
        set { pointer[position] = newValue }
    }
    
    var startIndex: Int { 0 }
    var endIndex: Int { currentEndIndex }
}
