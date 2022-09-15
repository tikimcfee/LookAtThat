//
//  MetalGlyphError.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/14/22.
//

import Foundation

enum MetalGlyphError: String, Error {
    case noBitmaps
    case noTextures
    case noMesh
    case noAtlasTexture
}
