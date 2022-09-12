//
//  ContentSizing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

protocol ContentSizing {
    var contentWidth: Float { get }
    var contentHeight: Float { get }
    var contentDepth: Float { get }
    var size: LFloat3 { get }
    var offset: LFloat3 { get }
}

extension ContentSizing {
    var size: LFloat3 { LFloat3(contentWidth, contentHeight, contentDepth) }
    var offset: LFloat3 { LFloat3(0, 0, 0) }
}

extension MetalLinkGlyphNode: ContentSizing {
    var contentWidth: Float { quad.width }
    var contentHeight: Float { quad.height }
    var contentDepth: Float { 1.0 }
}
