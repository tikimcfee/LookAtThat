//
//  Collections+Extensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/30/22.
//

import Foundation

extension Set {
    enum Selection {
        case addedToSet, removedFromSet
    }
    
    mutating func toggle(_ toggled: Element) -> Selection {
        if contains(toggled) {
            remove(toggled)
            return .removedFromSet
        } else {
            insert(toggled)
            return .addedToSet
        }
    }
}
