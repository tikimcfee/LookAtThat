//
//  CombineExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation
import SwiftUI

public class WrappedBinding<Value> {
    private var current: Value
    private var onSet: ((Value) -> Void)?
    init(_ start: Value) {
        self.current = start
    }
    init(_ start: Value, onSet: @escaping (Value) -> Void) {
        self.current = start
        self.onSet = onSet
    }
    lazy var binding = Binding<Value>(
        get: { return self.current },
        set: { (val: Value) in
            self.current = val
            self.onSet?(val)
        }
    )
}
