//
//  MetalLinkMaterial.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import simd

struct MetalLinkMaterial: MemoryLayoutSizable {
    var color = LFloat4(0.03, 0.33, 0.22, 1.0)
    
    // Flag that currently implies:
    // Hey, we didn't actually set the color yet. Don't show it. Or whatever.
    var useMaterialColor = false
}

