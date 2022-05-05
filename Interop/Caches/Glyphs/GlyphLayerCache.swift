//
//  The world is too pretty to not know it is.
//

import Foundation
import SceneKit

public typealias SizedText = (SCNGeometry, CGSize)

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

class FocusNode: SCNNode {
    var rootGeometry: SCNGeometry
    var focusGeometry: SCNGeometry
    
    init(
        _ root: SCNGeometry,
        _ focus: SCNGeometry
    ) {
        self.rootGeometry = root
        self.focusGeometry = focus
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func focus() {
        geometry = focusGeometry
    }
    
    func defocus() {
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
