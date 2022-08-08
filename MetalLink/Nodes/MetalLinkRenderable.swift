//
//  LinkRenderable.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

protocol MetalLinkRenderable {
    func doRender(in sdp: inout SafeDrawPass)
}
