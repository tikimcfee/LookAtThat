//
//  The world is too pretty to not know it is.
//

import Foundation

public struct GlyphCacheKey: Hashable, Equatable {
    public let source: Character
    public let glyph: String
    public let foreground: NSUIColor
    public let background: NSUIColor
    
    public init(source: Character,
                _ foreground: NSUIColor,
                _ background: NSUIColor = NSUIColor.black) {
        self.source = source
        self.glyph = String(source)
        self.foreground = foreground
        self.background = background
    }
}
