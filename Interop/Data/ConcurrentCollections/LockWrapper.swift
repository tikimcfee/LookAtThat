//
//  RWLock.swift
//  SwiftConcurrentCollections
//
//  Created by Pete Prokop on 09/02/2020.
//  Copyright © 2020 Pete Prokop. All rights reserved.
//

import Foundation

final class LockWrapper {
    private var lock = UnfairLock()

    // MARK: Public
    public func writeLock() {
        lock.lock()
    }

    public func readLock() {
        lock.lock()
    }

    public func unlock() {
        lock.unlock()
    }
}

final class UnfairLock: NSLocking {
    private let unfairLock: UnsafeMutablePointer<os_unfair_lock_s> = {
        let pointer = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock_s())
        return pointer
    }()
    
    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }
    
    func lock() {
        os_unfair_lock_lock(unfairLock)
    }
    
    func tryLock() -> Bool {
        os_unfair_lock_trylock(unfairLock)
    }
    
    func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

extension UnfairLock {
    func withAcquiredLock(_ action: () -> Void) {
        lock()
        action()
        unlock()
    }
    
    func withAcquiredLock<T>(_ action: () -> T) -> T {
        lock()
        let result = action()
        unlock()
        return result
    }
}
