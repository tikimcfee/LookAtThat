//
//  CodeGridBlitterBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/7/21.
//

import Foundation
import SceneKit

class CodeGridBlitter: Identifiable {
    let id: String
    
    lazy var backgroundGeometryNode = SCNNode()
    lazy var gridGeometry = makeGridGeometry()
    lazy var rootNode: SCNNode = makeContainerNode(id)
    
    init(_ id: String) {
        self.id = "\(id)-blitter"
    }
    
    private func makeContainerNode(_ id: String) -> SCNNode {
        let container = SCNNode()
        container.name = id
        container.addChildNode(backgroundGeometryNode)
        backgroundGeometryNode.geometry = gridGeometry
        backgroundGeometryNode.categoryBitMask = HitTestType.codeGridBlitter.rawValue
        backgroundGeometryNode.name = container.name
        return container
    }
    
    private func makeGridGeometry() -> SCNBox {
        let sheetGeometry = SCNBox()
        sheetGeometry.chamferRadius = 4.0
        sheetGeometry.firstMaterial?.diffuse.contents = NSUIColor.black
        sheetGeometry.length = PAGE_EXTRUSION_DEPTH
        return sheetGeometry
    }
    
    func sizeGridToContainerNode(
        pad: VectorFloat = 2.0,
        pivotRootNode: Bool = false
    ){
        gridGeometry.width = rootNode.lengthX.cg + pad.cg
        gridGeometry.height = rootNode.lengthY.cg + pad.cg
        let centerX = gridGeometry.width / 2.0
        let centerY = -gridGeometry.height / 2.0
        backgroundGeometryNode.position.x = centerX.vector - pad / 2.0
        backgroundGeometryNode.position.y = centerY.vector + pad / 2.0
        backgroundGeometryNode.position.z = -1
        // Can help in some layout situations where you want the root node's position
        // to be at dead-center of background geometry
        if pivotRootNode {
            rootNode.pivot = SCNMatrix4MakeTranslation(centerX.vector, centerY.vector, 0)
        }
    }
    
    func createBackingFlatLayer(
        _ fullTextLayerBuilder: FullTextLayerBuilder,
        _ finalAttributedString: NSMutableAttributedString
    ) {
        let (geometry, size) = fullTextLayerBuilder.make(finalAttributedString)
        
        let centerX = size.width / 2.0
        let centerY = -size.height / 2.0
        let pivotCenterToLeadingTop = SCNMatrix4MakeTranslation(-centerX.vector, -centerY.vector, 0)
        
        let layerNode = SCNNode()
        layerNode.geometry = geometry
        layerNode.pivot = pivotCenterToLeadingTop
        layerNode.categoryBitMask = HitTestType.codeGridSnapshot.rawValue
        
        rootNode.addChildNode(layerNode)
        
        sizeGridToContainerNode()
    }
}

class FullTextLayerBuilder {

    #if os(iOS)
    private static let FONT_SIZE = 8.0
    private let SCALE_FACTOR = 8.0
    private let DESCALE_FACTOR = 8.0
    #else
    private static let FONT_SIZE = 16.0
    private let SCALE_FACTOR = 1.0
    private let DESCALE_FACTOR = 12.0
    #endif
    
    private static let MONO_FONT = NSUIFont.monospacedSystemFont(ofSize: FONT_SIZE, weight: .regular)
    
    static let layoutQueue = DispatchQueue(label: "FullTextLayerBuilder=\(UUID())", qos: .userInitiated, attributes: [.concurrent])
    let fontRenderer = FontRenderer()
    
    func make(_ safeString: NSMutableAttributedString) -> (geometry: SCNGeometry, size: CGSize) {
        // Size the glyph from the font using a rendering scale factor
        safeString.addAttributes(
            [.font: Self.MONO_FONT],
            range: safeString.string.fullNSRange
        )
        let wordSize = safeString.size()
        //        let wordSizeScaled = CGSize(width: wordSize.width * SCALE_FACTOR,
        //                                    height: wordSize.height * SCALE_FACTOR)
        let wordSizeScaled = CGSize(width: wordSize.width * SCALE_FACTOR,
                                    height: wordSize.height * SCALE_FACTOR)
        
        // Create and configure text layer
        let textLayer = CATextLayer()
        textLayer.alignmentMode = .left
        textLayer.string = safeString
        textLayer.font = fontRenderer.font
        textLayer.fontSize = wordSizeScaled.height
        textLayer.frame.size = textLayer.preferredFrameSize()
        
        // Resize the final layer according to descale factor
        let descaledWidth = textLayer.frame.size.width / DESCALE_FACTOR
        let descaledHeight = textLayer.frame.size.height / DESCALE_FACTOR
        let descaledSize = CGSize(width: descaledWidth, height: descaledHeight)
        let boxPlane = SCNPlane(width: descaledWidth, height: descaledHeight)
        
        // Create bitmap on queue, set the layer on main. May want to batch this.
        Self.layoutQueue.async {
            // For whatever reason, we need to call display() manually. Or at least,
            // in this particular commit, the image is just blank without it.
            textLayer.display()
            let bitmap = textLayer.getBitmapImage()
            DispatchQueue.main.async {
                boxPlane.firstMaterial?.diffuse.contents = bitmap
            }
        }
        
        return (boxPlane, descaledSize)
    }
}
