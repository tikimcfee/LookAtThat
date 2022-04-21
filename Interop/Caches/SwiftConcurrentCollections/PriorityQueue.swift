//
//  PriorityQueue.swift
//  SwiftConcurrentCollections
//
//  Created by Petr Prokop on 27/11/2020.
//  Copyright © 2020 Pete Prokop. All rights reserved.
//

import Foundation

private let defaultCapacity = 16

public struct PriorityQueue<Element> {
    public typealias ComplexComparator = (Element, Element) -> ComparisonResult
    public typealias Comparator = (Element, Element) -> Bool

    private var container: [Element]
    private var heapSize = 0
    private let comparator: Comparator

    public var count: Int {
        return heapSize
    }

    public init(capacity: Int, complexComparator: @escaping ComplexComparator) {
        self.init(
            capacity: capacity,
            comparator: {
                complexComparator($0, $1) == .orderedAscending
            }
        )
    }

    public init(capacity: Int, comparator: @escaping Comparator) {
        self.comparator = comparator

        container = Array<Element>()
        container.reserveCapacity(capacity)
    }

    /// Creates `PriorityQueue` with default capacity
    /// - Parameter comparator: heap property will hold if `comparator(parent(i), i)` is `true`
    ///     e.g. `<` will create a minimum-queue and `>` - maximum-queue
    public init(_ comparator: @escaping Comparator) {
        self.init(capacity: defaultCapacity, comparator: comparator)
    }

    mutating public func insert(_ value: Element) {
        if heapSize == container.capacity {
            let reserveSize = container.count > 0 ? container.count : defaultCapacity
            container.reserveCapacity(container.count + reserveSize)
        }

        var i = heapSize
        container.append(value)
        heapSize += 1

        while !comparator(container[parent(i)], container[i])
            && i != 0
        {
            (container[i], container[parent(i)]) = (container[parent(i)], container[i])
            i = parent(i)
        }
    }

    /// Remove top element from the queue
    mutating public func pop() -> Element {
        if heapSize <= 0 {
            fatalError("Fatal error: trying to pop from an empty PriorityQueue")
        }

        if heapSize == 1 {
            heapSize -= 1
            return container.popLast()!
        }

        let root = container[0]
        container[0] = container.popLast()!
        heapSize -= 1
        heapify(0)

        return root
    }

    /// Get top element from the queue
    public func peek() -> Element {
        if heapSize <= 0 {
            fatalError("Fatal error: trying to peek into an empty PriorityQueue")
        }

        return container[0]
    }

    // MARK: Private
    
    @inline(__always)
    private func parent(_ i: Int) -> Int {
        return (i - 1) / 2
    }

    @inline(__always)
    private func left(_ i: Int) -> Int {
        return 2 * i + 1
    }

    @inline(__always)
    private func right(_ i: Int) -> Int {
        return 2 * i + 2
    }

    /// Recursively heapify a subtree with the root at given index
    /// Assumes that the subtrees are already heapified
    private mutating func heapify(_ i: Int) {
        let l = left(i)
        let r = right(i)
        var chosen = i

        if l < heapSize && comparator(container[l], container[i]) {
            chosen = l
        }

        if r < heapSize && comparator(container[r], container[chosen]) {
            chosen = r
        }

        if chosen != i {
            (container[i], container[chosen]) = (container[chosen], container[i])
            heapify(chosen)
        }
    }

}
