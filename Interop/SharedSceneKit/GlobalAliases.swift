import Foundation
import SwiftUI
import SceneKit

#if os(OSX)
public typealias NSUIPreview = NSViewRepresentableContext<SceneKitRepresentableView>
public typealias NSUIColor = NSColor
public typealias GestureRecognizer = NSGestureRecognizer
public typealias PanGestureRecognizer = NSPanGestureRecognizer
public typealias PanGestureRecognizerState = NSPanGestureRecognizer.State
public typealias MagnificationGestureRecognizer = NSMagnificationGestureRecognizer
public typealias MagnificationGestureRecognizerState = NSMagnificationGestureRecognizer.State
public typealias NSUIFont = NSFont
public typealias NSUIBezierPath = NSBezierPath
public typealias OSEvent = NSEvent
public typealias VectorFloat = CGFloat
public typealias OSScreen = NSScreen
#elseif os(iOS)
public typealias NSUIColor = UIColor
public typealias GestureRecognizer = UIGestureRecognizer
public typealias PanGestureRecognizer = UIPanGestureRecognizer
public typealias PanGestureRecognizerState = UIPanGestureRecognizer.State
public typealias MagnificationGestureRecognizer = UIPinchGestureRecognizer
public typealias MagnificationGestureRecognizerState = UIPinchGestureRecognizer.State
public typealias NSUIFont = UIFont
public typealias NSUIBezierPath = UIBezierPath
public typealias OSEvent = UIEvent
public typealias VectorFloat = Float
public typealias OSScreen = UIScreen
#endif

extension CGFloat {
    var vector: VectorFloat {
        return VectorFloat(self)
    }

    var cg: CGFloat {
        return self
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

typealias VoidCompletion = () -> Void
