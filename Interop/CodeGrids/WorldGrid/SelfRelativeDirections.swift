//
//  WorldGrid+Directions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

enum SelfRelativeDirection: String, Hashable, CaseIterable {
    case forward
    case backward
    case left
    case right
    case up
    case down
    
    case yawLeft
    case yawRight
}

extension SelfRelativeDirection: Comparable {
    static func < (lhs: SelfRelativeDirection, rhs: SelfRelativeDirection) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
