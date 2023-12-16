//
//  ReailtyDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 6/16/23.
//

import SwiftUI
import RealityKit
import MetalLink
import SwiftGlyph

struct CubeARView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Create the cube entity
        let boxMesh = MeshResource.generateBox(size: 0.2, cornerRadius: 0.02)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [material])

        // Add the cube entity to the scene
        let anchorEntity = AnchorEntity()
        anchorEntity.addChild(boxEntity)
        
        
        let parent = AnchorEntity()
        parent.addChild(anchorEntity)
        
        arView.scene.addAnchor(parent)
        
        var angle = 0.0.float
        let axis = LFloat3(1, 0, 0)
        
        QuickLooper(interval: .milliseconds(100), loop: {
            angle += 0.1
//            axis += LFloat3(repeating: 0.1)
            
            parent.setPosition(parent.position.translated(dX: cos(angle)), relativeTo: nil)
//            anchorEntity.setPosition(parent.position.translated(dX: cos(angle) / 10), relativeTo: nil)
            
            anchorEntity.orientation = .init(angle: cos(angle), axis: axis)
            
            print(parent.visualBounds(recursive: true, relativeTo: nil))
        }).runUntil { false }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct ARBasicView : View {
    var body: some View {
        VStack {
            Text("AR Cube Example")
                .font(.title)
                .padding()

            CubeARView()
                .edgesIgnoringSafeArea(.all)
                .frame(width: 300, height: 500)
        }
    }
}

#if DEBUG
struct ARBasicView_Previews : PreviewProvider {
    static var previews: some View {
        ARBasicView()
    }
}
#endif

