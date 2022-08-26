//
//  CharacterExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

extension Character {
    struct Check {
        let isWhitespace: Bool
        let isNewline: Bool
    }
    
    private class CheckCaches: LockingCache<Character, Check> {
        static let shared: CheckCaches = CheckCaches()
        override func make(_ key: Key, _ store: inout [Key : Value]) -> Character.Check {
            Check(
                isWhitespace: CharacterSet.whitespacesAndNewlines.containsUnicodeScalars(of: key),
                isNewline: key.isNewline
            )
        }
    }
    
    var checks: Check {
        CheckCaches.shared[self]
    }
    
    var isWhitespaceCharacter: Bool {
        CheckCaches.shared[self].isWhitespace
    }
    
    var isNewlineCharacter: Bool {
        CheckCaches.shared[self].isNewline
    }
}

extension CharacterSet {
    func containsUnicodeScalars(of character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}
