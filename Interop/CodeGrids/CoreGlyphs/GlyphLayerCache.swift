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

extension GlyphCacheKey {
    var asPersistedName: Name? { Name(self) }
}

extension GlyphCacheKey {
    struct Name {
        static let Separator: Character = "_"
        let glyph: String
        let foreground: String
        let background: String
        
        init?(_ key: GlyphCacheKey) {
            guard let safeHexName = key.glyph.safeHexString else {
                return nil
            }
            self.glyph = safeHexName
            self.foreground = CIColor(cgColor: key.foreground.cgColor).stringRepresentation
            self.background = CIColor(cgColor: key.background.cgColor).stringRepresentation
        }
        
        init?(_ rawComponent: String) {
            let components = rawComponent
                .split(separator: Self.Separator)
                .compactMap { String($0) }
            guard components.count == 3 else { return nil }
            
            self.glyph = components[0]
            self.foreground = components[1]
            self.background = components[2]
        }
        
        var fileNameComponent: String {
            [glyph, foreground, background]
                .joined(separator: String(Self.Separator))
        }
        
        var asCacheKey: GlyphCacheKey? {
            guard let foreground = foreground.asCIColor,
                  let background = background.asCIColor,
                  let glyphText = glyph.convertedFromHexToText else {
                return nil
            }
            return GlyphCacheKey(
                glyphText,
                foreground,
                background
            )
        }
    }
}

extension StringProtocol {
    var asCIColor: NSUIColor? {
        let color = CIColor(string: String(self))
        let fromCi = NSUIColor(ciColor: color)
        let fromCiRGBA = fromCi.rgba
        let p3 = NSUIColor(displayP3Red: fromCiRGBA.red,
                           green: fromCiRGBA.green,
                           blue: fromCiRGBA.blue,
                           alpha: fromCiRGBA.alpha
        )
        return p3
    }
}

extension StringProtocol {
    var hexadecimalData: Data { Data(hexadecimalSequence) }
    var hexadecimalBytes: [UInt8] { Array(hexadecimalSequence) }
    var safeHexString: String? { data(using: .utf8)?.hexString }
    
    var convertedFromHexToText: String? {
        let hexToData = hexadecimalData
        let dataToString = String(data: hexToData, encoding: .utf8)
        return dataToString
    }

    private var hexadecimalSequence: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

extension Data {
    var hexString: String {
        let utfData = Data(self)
        return utfData.map{ String(format:"%02x", $0) }.joined()
    }
}
