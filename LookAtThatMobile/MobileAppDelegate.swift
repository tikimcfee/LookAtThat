//
//  AppDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import UIKit
import SwiftUI

@main
struct MobileAppDelegate: App {
    
    @State private var rootImmersionStyle: ImmersionStyle = .full
    
    var body: some Scene {
        WindowGroup(id: "glyphee") {
             
//            MobileAppRootView()
        }
        
        #if os(xrOS)
        ImmersiveSpace {
            MetalLinkXRView()
        }.immersionStyle(selection: $rootImmersionStyle, in: .full)
        #endif
     }
}
