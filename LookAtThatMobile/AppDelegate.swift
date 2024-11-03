//
//  AppDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import UIKit
import SwiftUI
import SwiftGlyph

@main
struct AppDelegate: App {
    
    var body: some Scene {
        WindowGroup(id: "glyphee") {
            SwiftGlyphDemoView()

            // Soon...
//            CubeARView()
        }
     }
}
