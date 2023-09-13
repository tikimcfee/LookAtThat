//
//  WordDictionaries.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation
import SwiftNodes

enum PartOfSpeech: String, Codable, Equatable, Hashable {
    case noun
    case transitiveVerb = "transitiveVerb"
    case interjection
    case idiom
    case intransitiveVerb = "intransitiveVerb"
    case verb
    case adverb
    case definiteArticle = "definite article."
    case adjective
}

struct WordnikPartOfSpeech: Codable, Hashable, Equatable {
//    let name: String
    let name: PartOfSpeech
}

struct WordnikDefinition: Codable, Hashable, Equatable {
    let xref: String?
    let src: String
    let txt: String
    let pos: WordnikPartOfSpeech?
}

struct WordnikWord: Codable, Hashable, Equatable {
    let _id: String
    let word: String
    let df: [WordnikDefinition]
}

typealias WordnikMap = [String: [String]]

struct WordnikGameDictionary: Codable, Hashable, Equatable {
    var words: [WordnikWord]
    var map: WordnikMap
    
    init(from file: URL) {
        let decodedWords = try! JSONDecoder().decode(
            [WordnikWord].self,
            from: Data(contentsOf: file, options: .alwaysMapped)
        )
        self.words = decodedWords
        self.map = decodedWords
            .reduce(into: WordnikMap()) {
                Self.reduceOnInit(word: $1, map: &$0)
            }
        
//        let filtered = words
//            .lazy
//            .reduce(into: [PartOfSpeech: Set<WordnikWord>]()) { result, word in
//                for definition in word.df {
//                    if let name = definition.pos?.name {
//                        result[name, default: []].insert(word)
//                    }
//                }
//            }
//
//        print(filtered)
    }
    
    private static func reduceOnInit(
        word: WordnikWord,
        map: inout WordnikMap
    ) {
        let definitionWords = word.df.lazy.reduce(into: Set<String>()) { result, value in
            value.txt.splitToWords.lazy.forEach { word in
                result.insert(word.dewordnikked)
            }
        }
        
        let finalWords = Array(definitionWords)
        map[word.word.dewordnikked, default: []].append(contentsOf: finalWords)
        
        finalWords.forEach { definitionWord in
            guard map[definitionWord] == nil else { return }
            map[definitionWord] = []
        }
    }
}

extension String {
    var dewordnikked: String {
        trimmingCharacters(
            in: .alphanumerics.inverted
        )
        .lowercased()
    }
}

extension WordGraph {
    mutating func addWeightBetween(source: String, target: String) {
        insert(target)
        add(
            0.1,
            toEdgeWith: WordGraph.Edge(
                from: source,
                to: target
            ).id
        )
    }
}

typealias WordGraph = Graph<String, String, Float>

struct WordDictionary {
    var words: [String: [String]]
    var graph: WordGraph
    
    var orderedWords: [String: [[String]]] = [:]
    
    init() {
        self.words = .init()
        self.graph = .init()
    }
    
    init(
        words: [String: [String]],
        graph: WordGraph? = nil
    ) {
        self.words = words
        
        var graph = graph ?? WordGraph()
        words.forEach { (sourceWord, definitionWords) in
            graph.insert(sourceWord)
            
            for definitionWord in definitionWords {
                graph.addWeightBetween(source: sourceWord, target: definitionWord)
            }
        }
        self.graph = graph
    }
    
    init(file: URL) {
        let decodedWords = try! JSONDecoder().decode(
            [String: [String]].self,
            from: Data(contentsOf: file, options: .alwaysMapped)
        )
        
        let orderedDefinitionWords = decodedWords.reduce(
            into: [String: [[String]]]()
        ) { result, entry in
            let sourceWord = entry.key.dewordnikked
            var currentArray = result[sourceWord, default: []]
                
            for definition in entry.value {
                let definitionWords = definition.splitToWords.map {
                    let cleaned = $0.dewordnikked
                    return cleaned
                }
                currentArray.append(definitionWords)
            }
            
            result[sourceWord] = currentArray
        }
        
        self.orderedWords = orderedDefinitionWords
        self.words = [:]
        self.graph = .init()
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
