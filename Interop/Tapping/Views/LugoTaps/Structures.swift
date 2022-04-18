//
//  Structures.swift
//  IOTAPS
//
//  Created by Ivan Lugo on 10/5/21.
//  Copyright © 2021 Shahar Biran. All rights reserved.
//

import Foundation

class LList<NodeValue>: Sequence {
	typealias Node = LNode<NodeValue>

	private var head: Node?
	private var tail: Node?
	
	func removeAll() {
		head = nil
		tail = nil
	}
	
	func append(_ value: NodeValue) {
		listAppend(LNode(value))
	}
	
	private func listAppend(_ node: Node) {
		if head == nil {
			head = node
		}
		tail?.next = node
		tail = node
	}
	
	func makeIterator() -> LLIterator {
		LLIterator(pointer: head)
	}
}

extension LList {
	struct LLIterator: IteratorProtocol {
		var pointer: Node?
		var lastNodeOnEmpty: Node?
		
		mutating func next() -> NodeValue? {
			if pointer == nil && lastNodeOnEmpty?.next != nil {
				pointer = lastNodeOnEmpty?.next
				lastNodeOnEmpty = nil
			}
			if let pointer = pointer, pointer.next == nil {
				lastNodeOnEmpty = pointer
			}
			
			let currentNode = pointer
			pointer = pointer?.next
			
			return currentNode?.element
		}
	}
}

class LNode<Element> {
	typealias Node = LNode<Element>
	var element: Element?
	var next: Node?
	init(_ element: Element) {
		self.element = element
	}
}
