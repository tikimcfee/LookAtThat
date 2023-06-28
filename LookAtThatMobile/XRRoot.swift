//
//  ReailtyDelegate.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 6/16/23.
//

import SwiftUI
import RealityKit
import MetalLink
import RealityGeometries

struct MetalLinkXRView: View {
    @StateObject var viewState: XRViewState = XRViewState()
    
    var body: some View {
        RealityView { content in
            // All content must be added to the view, even if they are children of
            // an existing entity. Ok, sure, makes sense in an entity/component system kinda way.
            content.add(viewState.entlytree)
            content.add(viewState.entlytree2)
        } update: { content in
            // Reconfigure everything when any configuration changes.
        }
        .onAppear(perform: {
            viewState.playWithEntlytree()
        })
    }
}

class XRViewState: ObservableObject {
    lazy var entlytree: ModelEntity = makeTestEntlytrees(.red)
    lazy var entlytree2: ModelEntity = makeTestEntlytrees(.blue)
    
    func playWithEntlytree() {
        var transform = entlytree2.transform
        transform.translation = transform.translation.translateBy(dX: 0.1, dY: 0.1, dZ: 0.1)
        entlytree2.transform = transform
        
        print("[\(#fileID)] setting child")
        entlytree.addChild(entlytree2)
    }
    
    func makeTestEntlytrees(_ color: UIColor) -> ModelEntity {
        let newMesh: MeshResource
        do {
            newMesh = try MeshResource.generateDetailedPlane(
                width: 0.1,
                depth: 0.1,
                vertices: (10, 10)
            )
        } catch {
            fatalError("[xrviewstate] error generating plane: \(error)")
        }
        
        print("[xrviewstate] mesh bounds: ", newMesh.bounds)
        
        let simpleMaterial = SimpleMaterial(
            color: color,
            roughness: .float(0.5),
            isMetallic: true
        )
        
        let modelEntity = ModelEntity(
            mesh: newMesh,
            materials: [simpleMaterial]
        )
        
        modelEntity.name = "EntlyTreeTestGeometryEntity+\(UUID().uuidString)"
        modelEntity.transform.rotation = .init(angle: .pi / 2, axis: LFloat3(1, 0, 0))
        
        return modelEntity
    }
}

#Preview {
    MetalLinkXRView(
        
    )
}

