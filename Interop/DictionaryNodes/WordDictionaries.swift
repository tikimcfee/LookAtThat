//
//  WordDictionaries.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation

struct WordDictionary: Codable {
    var words: [String: [String]]
    
    init() {
        self.words = .init()
    }
    
    init(file: URL) {
        self.words = try! JSONDecoder().decode(
            [String: [String]].self,
            from: Data(contentsOf: file, options: .alwaysMapped)
        ).reduce(into: [String: [String]]()) { result, element in
            if let firstDefinition = element.value.first {
                let cleanedWords = firstDefinition.splitToWords.map { word in
                    word.trimmingCharacters(
                        in: .alphanumerics.inverted
                    ).lowercased()
                }
                result[element.key.lowercased()] = cleanedWords
            }
        }
    }
}

struct SortedDictionary {
    let sorted: [(String, [String])]
    
    init() {
        self.sorted = .init()
    }
    
    init(dictionary: WordDictionary) {
        self.sorted = dictionary.words.sorted(by: { left, right in
            left.key.caseInsensitiveCompare(right.key) == .orderedAscending
//            left.key < right.key
        })
    }
}
