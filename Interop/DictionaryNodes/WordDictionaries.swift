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
        let definitionWords = word.df.lazy.compactMap {
            $0.txt.splitToWords.map {
                $0.dewordnikked
            }
        }.flatMap { $0 }
        let finalWords = Array(Set(definitionWords))
        map[word.word.dewordnikked, default: []].append(contentsOf: finalWords)
        finalWords.lazy.forEach { definitionWord in
            if !map.keys.contains(where: { $0 == definitionWord }) {
                map[definitionWord] = []
            }
        }
    }
}

private extension String {
    var dewordnikked: String {
        trimmingCharacters(
            in: .alphanumerics.inverted
        )
        .lowercased()
    }
}

typealias WordGraph = Graph<String, String, Double>
struct WordDictionary {
    var words: [String: [String]]
    var graph: WordGraph
    
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
                graph.insert(definitionWord)
                graph.add(
                    weight: 1.0,
                    toEdgeWith: WordGraph.Edge(
                        from: sourceWord,
                        to: definitionWord
                    ).id
                )
            }
        }
        self.graph = graph
    }
    
    init(file: URL) {
        var wordGraph = WordGraph()
        self.words = try! JSONDecoder().decode(
            [String: [String]].self,
            from: Data(contentsOf: file, options: .alwaysMapped)
        ).reduce(into: [String: [String]]()) { result, element in
            if let firstDefinition = element.value.first {
                let sourceWord = element.key.lowercased()
                wordGraph.insert(sourceWord)
                
                let cleanedWords = firstDefinition.splitToWords.map { definitionWord in
                    let trimmed = definitionWord.trimmingCharacters(
                        in: .alphanumerics.inverted
                    ).lowercased()
                    
                    wordGraph.insert(trimmed)
                    wordGraph.add(
                        weight: 1.0,
                        toEdgeWith: WordGraph.Edge(from: sourceWord, to: trimmed).id
                    )
                    
                    return trimmed
                }
                
                result[sourceWord] = cleanedWords
            }
        }
        self.graph = wordGraph
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
