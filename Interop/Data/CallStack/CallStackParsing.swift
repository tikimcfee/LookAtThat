//
//  CallStackParsing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

struct CallStackParsing {
    private static let Module = "LookAtThat_AppKit"
    private static let StopCharacters = CharacterSet(charactersIn: "():")
    
    static func callComponents(from signature: String) -> (callPath: String, allComponents: [String]) {
        var shouldContinue = true
        var allComponents = [String]()
        let simplifiedStack = signature
            .components(separatedBy: ".")
            .reduce(into: "") { currentPath, component in
                guard shouldContinue, component != Self.Module else { return }
                let (cleanedComponent, foundStop) = Self.cleanComponent(component)
                
                shouldContinue = !foundStop
                allComponents.append(cleanedComponent)
                if currentPath.isEmpty {
                    currentPath.append(cleanedComponent)
                } else {
                    currentPath.append(".\(cleanedComponent)")
                }
            }
        return (simplifiedStack, allComponents)
    }
    
    private static func cleanComponent(_ component: String) -> (String, foundStop: Bool) {
        var foundStop = false
        let prefixed = component.prefix(while: { character in
            foundStop = !character.unicodeScalars.allSatisfy { !StopCharacters.contains($0) }
            return !foundStop
        })
        let trimmed = String(prefixed).trimmingCharacters(in: CharacterSet.whitespaces)
        return (trimmed, foundStop)
    }
}
