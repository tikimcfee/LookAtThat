//
//  RootSceneState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

class SceneState {
    
    private(set) var rootNode: RootNode
    
    var rootCameraNode: MetalLinkCamera
    
    init(
        rootNode: RootNode,
        rootCameraNode: MetalLinkCamera
    ) {
        self.rootNode = rootNode
        self.rootCameraNode = rootCameraNode
    }
}

extension SceneState {
    class GridMeta {
        var searchFocused = false
    }
}

enum SceneControllerError: Error, Identifiable {
    case missingWord(query: String)
    case noWordToTrack(query: String)
    
    typealias ID = String
    var id: String {
        switch self {
        case .missingWord(let query):
            return query
        case .noWordToTrack(let query):
            return query
        }
    }
}

