//
//  FontRenderer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/5/22.
//

import Foundation
import SceneKit

struct FontRenderer {
    static let shared: FontRenderer = FontRenderer()
    
    let font: NSUIFont = MONOSPACE_FONT
    let unitFont: NSUIFont = UNIT_FONT
    
    private init() { }
}

extension FontRenderer {
    func measure(_ text: String) -> (CGSize, CGSize) {
        let textSize = text.size(withAttributes: [.font: font])
        let textSizeScaled = CGSize(
            width: textSize.width * Self.SCALE_FACTOR,
            height: textSize.height * Self.SCALE_FACTOR
        )
        return (textSize, textSizeScaled)
    }
    
    func descale(_ size: CGSize) -> CGSize {
        let descaledWidth = size.width / Self.DESCALE_FACTOR
        let descaledHeight = size.height / Self.DESCALE_FACTOR
        return CGSize(width: descaledWidth, height: descaledHeight)
    }
}

private extension FontRenderer {
#if os(iOS)
    static let FONT_SIZE = 16.0
    static let SCALE_FACTOR = 1.0
    static let DESCALE_FACTOR = 16.0
#else
    static let FONT_SIZE = 24.0
    static let SCALE_FACTOR = 1.0
    static let DESCALE_FACTOR = 24.0
#endif
    
    // TODO: !WARNING! NOTE! PAY ATTENTION!
    // I never realized this, but I was using the `WORD_POINT_SIZE` font when making glyphs,
    // and measuring with a sized font... and if you don't do that, you end up with things not
    // working correctly, as the font will take into account all sorts of text measuring stuff.
    // So, we use UNIT_FONT when requesting a text-layer to render, and MONOSPACE_FONT to
    static let MONOSPACE_FONT = NSUIFont.monospacedSystemFont(ofSize: FONT_SIZE, weight: .regular)
    static let UNIT_FONT = NSUIFont.monospacedSystemFont(ofSize: 1.0, weight: .regular)
}
