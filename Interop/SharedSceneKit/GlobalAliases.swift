import Foundation
import SwiftUI
import SceneKit

#if os(OSX)
public typealias NSUIColor = NSColor
public typealias GestureRecognizer = NSGestureRecognizer
public typealias TapGestureRecognizer = NSGestureRecognizer
public typealias PanGestureRecognizer = NSPanGestureRecognizer
public typealias PanGestureRecognizerState = NSPanGestureRecognizer.State
public typealias MagnificationGestureRecognizer = NSMagnificationGestureRecognizer
public typealias MagnificationGestureRecognizerState = NSMagnificationGestureRecognizer.State
public typealias NSUIFont = NSFont
public typealias NSUIBezierPath = NSBezierPath
public typealias OSEvent = NSEvent
public typealias VectorFloat = Float
public typealias OSScreen = NSScreen
public typealias NSUIImage = NSImage
public typealias NSUIViewRepresentable = NSViewRepresentable
#elseif os(iOS)
public typealias NSUIColor = UIColor
public typealias GestureRecognizer = UIGestureRecognizer
public typealias TapGestureRecognizer = UITapGestureRecognizer
public typealias PanGestureRecognizer = UIPanGestureRecognizer
public typealias PanGestureRecognizerState = UIPanGestureRecognizer.State
public typealias MagnificationGestureRecognizer = UIPinchGestureRecognizer
public typealias MagnificationGestureRecognizerState = UIPinchGestureRecognizer.State
public typealias NSUIFont = UIFont
public typealias NSUIBezierPath = UIBezierPath
public typealias OSEvent = UIEvent
public typealias VectorFloat = Float
public typealias OSScreen = UIScreen
public typealias NSUIImage = UIImage
public typealias NSUIViewRepresentable = UIViewRepresentable
#endif

extension VectorFloat {
    var toDouble: Double { Double(self) }
}

extension Double {
    var cg: CGFloat {
        return self
    }
//    var device: Double {
//        return self * DeviceScale
//    }
}

extension CGFloat {
    var vector: VectorFloat {
        return VectorFloat(self)
    }

    var cg: CGFloat {
        return self
    }
}

extension Int {
    var cg: CGFloat {
        return CGFloat(self)
    }
    
    var float: Float {
        return Float(self)
    }
}

extension Float {
    var vector: VectorFloat {
        return VectorFloat(self)
    }

    var cg: CGFloat {
        return CGFloat(self)
    }
}

extension CGSize {
    var asSimd: LFloat2 { LFloat2(width.float, height.float) }
}

extension CGFloat {
    var float: Float {
        return Float(self)
    }
}

typealias VoidCompletion = () -> Void
