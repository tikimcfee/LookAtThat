//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit

public struct GlyphCacheKey: Hashable, Equatable {
    public let glyph: String
    public let foreground: NSUIColor
    public let background: NSUIColor
    
    public init(_ glyph: String,
                _ foreground: NSUIColor,
                _ background: NSUIColor = NSUIColor.black) {
        self.glyph = glyph
        self.foreground = foreground
        self.background = background
    }
}

class GlyphLayerCache: LockingCache<GlyphCacheKey, SizedText> {
    
    let glyphBuilder = GlyphBuilder()
    
    override func make(_ key: GlyphCacheKey, _ store: inout [GlyphCacheKey: SizedText]) -> Value {
        return glyphBuilder.makeGlyph(key)
    }
    
    func diffuseMaterial(_ any: Any?) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = any
        return material
    }
}

extension SCNNode {
    private var diffuseMaterialWrapper: MaterialWrapper? {
        geometry?.firstMaterial as? MaterialWrapper
    }
    
    func updateDiffuseContents(_ index: Int) {
        print("\n\n\t\tDiffuse does not work - geometry is shared!!\n\n")
//        diffuseMaterialWrapper?.updateDiffuse(to: index)
    }
}

class GlyphNode: SCNNode {
    var rootGeometry: SCNGeometry!
    var focusGeometry: SCNGeometry!
    var size: CGSize!
    
    static func make(
        _ root: SCNGeometry,
        _ focus: SCNGeometry,
        _ size: CGSize
    ) -> GlyphNode {
        let node = GlyphNode()
        node.rootGeometry = root
        node.focusGeometry = focus
        node.size = size
        node.geometry = root
        return node
    }
    
    func focus() {
        geometry = focusGeometry
    }
    
    func reset() {
        geometry = rootGeometry
    }
}

class MaterialWrapper: SCNMaterial {
    var contentSwap: [Any] = []
    
    init(_ contents: Any...) {
        super.init()
        self.contentSwap = contents
        self.updateDiffuse(to: 0)
//        diffuse.contents = TopplerBlock.textureImage
//        diffuse.contentsTransform = SCNMatrix4MakeScale(0.5, 1.0, 0.0)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateDiffuse(to contentIndex: Int) {
        guard contentSwap.indices.contains(contentIndex) else {
            print("No content available at \(contentIndex)")
            return
        }
        diffuse.contents = contentSwap[contentIndex]
    }
    
//    var highlighted: Bool = false {
//        didSet {
//            // Prevent unneeded updates
//            guard highlighted != oldValue else { return }
//            diffuse.contents = highlighted ? TopplerBlockMaterial.highlightedImage : TopplerBlockMaterial.baseImage
//            let translateOffset: Float = highlighted ? 0.5 : 0.0
//            let scale = SCNMatrix4MakeScale(0.5, 1.0, 0.0)
//            let translateAndScale = SCNMatrix4Translate(scale, translateOffset, 0.0, 0.0)
//            diffuse.contentsTransform = translateAndScale
//        }
//    }
}
