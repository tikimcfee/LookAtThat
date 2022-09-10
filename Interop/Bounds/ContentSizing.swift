//
//  ContentSizing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

protocol ContentSizing {
    var width: Float { get }
    var height: Float { get }
    var depth: Float { get }
    var size: LFloat3 { get }
}

extension ContentSizing {
    var size: LFloat3 { LFloat3(width, height, depth) }
}

extension MetalLinkGlyphNode: ContentSizing {
    var width: Float { quad.width }
    var height: Float { quad.height }
    var depth: Float { 0.0 }
}
