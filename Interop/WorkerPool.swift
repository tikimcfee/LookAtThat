//
//  WorkerPool.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/16/22.
//

import Foundation

public final class WorkerPool {
    
    static let shared = WorkerPool()
    private let workerCount = (ProcessInfo.processInfo.processorCount - 1)
    
    private lazy var allWorkers =
    (0..<workerCount).map { DispatchQueue(
        label: "LugoWorkerPool-Serial-\($0)",
        qos: .userInitiated
    )}
    
    private lazy var concurrentWorkers =
    (0..<workerCount).map { DispatchQueue(
        label: "LugoWorkerPool-Concur-\($0)",
        qos: .userInitiated,
        attributes: .concurrent
    )}
    
    private lazy var workerIterator =
    allWorkers.makeIterator()
    
    private lazy var concurrentWorkerIterator =
    concurrentWorkers.makeIterator()
    
    private init() {}
    
    public func nextWorker() -> DispatchQueue {
        return workerIterator.next() ?? {
            workerIterator = allWorkers.makeIterator()
            let next = workerIterator.next()!
            return next
        }()
    }
    
    public func nextConcurrentWorker() -> DispatchQueue {
        return concurrentWorkerIterator.next() ?? {
            concurrentWorkerIterator = concurrentWorkers.makeIterator()
            let next = concurrentWorkerIterator.next()!
            return next
        }()
    }
}
