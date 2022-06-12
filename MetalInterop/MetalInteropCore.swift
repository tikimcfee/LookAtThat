//
//  MetalInteropCore.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/22.
//

import Foundation
import MetalKit
import SwiftUI

extension MetalView {
    private static let defaultMTKView: MTKView = MTKView()
    static func makeFromDefault() -> MetalView {
        MetalView(mtkView: defaultMTKView)
    }
}

