import Foundation
import SwiftUI
import SceneKit

#if os(OSX)
public typealias NSUIRepresentable = NSViewRepresentable
public typealias NSUIPreview = NSViewRepresentableContext<SceneKitView>
public typealias NSUIColor = NSColor
public typealias PanGestureRecognizer = NSPanGestureRecognizer
public typealias PanGestureRecognizerState = NSPanGestureRecognizer.State
public typealias NSUIFont = NSFont
public typealias NSUIBezierPath = NSBezierPath
#elseif os(iOS)
public typealias NSUIRepresentable = UIViewRepresentable
public typealias NSUIPreview = UIViewRepresentableContext<SceneKitView>
public typealias NSUIColor = UIColor
public typealias PanGestureRecognizer = UIPanGestureRecognizer
public typealias PanGestureRecognizerState = UIPanGestureRecognizer.State
public typealias NSUIFont = UIFont
public typealias NSUIBezierPath = UIBezierPath
#endif

typealias VoidCompletion = () -> Void
