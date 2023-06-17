//
//  ReailtyDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 6/16/23.
//

import SwiftUI
import RealityKit
import MetalLink

struct CubeARView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Create the cube entity
        let boxMesh = MeshResource.generateBox(size: 0.2)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [material])
        boxEntity.transform.rotation = .init(angle: 45, axis: LFloat3(1, 0, 0))

        // Add the cube entity to the scene
        let anchorEntity = AnchorEntity()
        anchorEntity.addChild(boxEntity)
        arView.scene.addAnchor(anchorEntity)

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

