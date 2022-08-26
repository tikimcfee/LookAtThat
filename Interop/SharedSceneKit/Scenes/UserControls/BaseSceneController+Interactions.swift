import Foundation
import SwiftUI
import SceneKit

typealias PanReceiver = (PanEvent) -> Void
typealias MagnificationReceiver = (MagnificationEvent) -> Void
typealias TapReceiver = (GestureEvent) -> Void

#if os(OSX)

class GestureShim {
    lazy var panRecognizer =
        ModifiersPanGestureRecognizer(target: self, action: #selector(pan))
    var onPan: PanReceiver

    lazy var magnificationRecognizer =
        ModifiersMagnificationGestureRecognizer(target: self, action: #selector(magnify))
    var onMagnify: MagnificationReceiver
    
    lazy var tapGestureRecognizer =
        TapGestureRecognizer(target: self, action: #selector(noop))
    var onTap: TapReceiver

    init(_ onPan: @escaping PanReceiver,
         _ onMagnify: @escaping MagnificationReceiver,
         _ onTap: @escaping TapReceiver) {
        self.onPan = onPan
        self.onMagnify = onMagnify
        self.onTap = onTap
        
        tapGestureRecognizer.isEnabled = false
    }

    @objc func pan(_ receiver: ModifiersPanGestureRecognizer) {
        onPan(receiver.makePanEvent)
    }

    @objc func magnify(_ receiver: ModifiersMagnificationGestureRecognizer) {
        onMagnify(receiver.makeMagnificationEvent)
    }
    
    @objc func noop(_ receiver: TapGestureRecognizer) {
        
    }
}

#elseif os(iOS)

class GestureShim {
    lazy var panRecognizer =
        PanGestureRecognizer(target: self, action: #selector(pan))
    var onPan: PanReceiver

    lazy var magnificationRecognizer =
        MagnificationGestureRecognizer(target: self, action: #selector(magnify))
    var onMagnify: MagnificationReceiver
    
    lazy var tapGestureRecognizer =
        TapGestureRecognizer(target: self, action: #selector(tap))
    var onTap: TapReceiver

    init(_ onPan: @escaping PanReceiver,
         _ onMagnify: @escaping MagnificationReceiver,
         _ onTap: @escaping TapReceiver) {
        self.onPan = onPan
        self.onMagnify = onMagnify
        self.onTap = onTap
    }
    
    @objc func tap(_ receiver: TapGestureRecognizer) {
        onTap(receiver.makeGestureEvent)
    }

    @objc func pan(_ receiver: PanGestureRecognizer) {
        onPan(receiver.makePanEvent)
    }

    @objc func magnify(_ receiver: MagnificationGestureRecognizer) {
        onMagnify(receiver.makeMagnificationEvent)
    }
}

#endif

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }

    func scaled(_ factor: CGFloat) -> CGPoint {
        return CGPoint(x: x * factor, y: y * factor)
    }
}

class TouchState {
    var magnify = MagnifyStart()
    var mouse = Mouse()
}

class Mouse {
    var currentPosition = CGPoint()
}

class MagnifyStart {
    var lastScaleZ = CGFloat(1.0)
}

