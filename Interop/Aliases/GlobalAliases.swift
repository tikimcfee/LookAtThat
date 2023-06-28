#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import SwiftUI

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

    #if !os(xrOS)
    public typealias OSScreen = UIScreen
    #endif

public typealias NSUIImage = UIImage
public typealias NSUIViewRepresentable = UIViewRepresentable
#endif
