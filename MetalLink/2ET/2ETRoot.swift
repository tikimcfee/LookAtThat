//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Foundation
import MetalKit

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    let linkObject: MetalLinkObject
    
    init(link: MetalLink) throws {
        self.link = link
        self.linkObject = try MetalLinkObject(link)
        
        setup()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        linkObject.render(in: &sdp)
    }
}

extension TwoETimeRoot {
    func setup() {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)   
    }
}
