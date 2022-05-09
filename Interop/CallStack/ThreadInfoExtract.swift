//
//  ThreadInfoExtract.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/29/22.
//

import Foundation

class ThreadInfoExtract {
    static let rawInfoRegex = #"\{(.*), (.*)\}"#
    static let infoRegex = try! NSRegularExpression(pattern: rawInfoRegex)
    private init() {}
    static func from(_ string: String) -> (number: String, name: String) {
        let range = NSRange(string.range(of: string)!, in: string)
        let matches = Self.infoRegex.matches(in: string, range: range)
        
        for match in matches {
            let maybeNumber = Range(match.range(at: 1), in: string).map { string[$0] } ?? ""
            let maybeName = Range(match.range(at: 2), in: string).map { string[$0] } ?? ""
            return (String(maybeNumber), String(maybeName))
        }
        return ("", "")
    }
}
