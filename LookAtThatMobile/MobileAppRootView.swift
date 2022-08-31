//
//  ContentView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 9/23/20.
//

import SwiftUI

#if os(iOS)
import ARKit
#endif

private extension MobileAppRootView {
    static var receiver: DefaultInputReceiver { DefaultInputReceiver.shared }
    static var keyEvent: OSEvent {
        get { receiver.lastKeyEvent }
        set { receiver.lastKeyEvent  = newValue }
    }
}

struct MobileAppRootView : View {
    @State var showInfoView = false
    @State var showGitFetch = false
    
    @State var touchStart: CGPoint? = nil
    @State var showMetal: Bool = false
    
    private let delta = CGFloat(20)
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            MetalView()
            gestureControl
        }
    }
    
    var gestureControl: some View {
        ZStack(alignment: .topLeading) {
            #if os(macOS) // used for previews
            Spacer()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray)
            #endif
            if let touch = touchStart {
                Circle()
                    .foregroundColor(Color.red)
                    .frame(width: 32, height: 32)
                    .offset(x: touch.x - 16, y: touch.y - 16)
                    .shadow(color: .red, radius: 3.0)
            }
        }.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { change in
                    if touchStart == nil { touchStart = change.startLocation }
                    
                    #if os(iOS)
                    if change.translation.width < -delta {
                        Self.keyEvent = .RightDragKeyup
                        Self.keyEvent = .LeftDragKeydown
                    } else {
                        Self.keyEvent = .LeftDragKeyup
                    }
                    
                    
                    if change.translation.width > delta {
                        Self.keyEvent = .LeftDragKeyup
                        Self.keyEvent = .RightDragKeydown
                    } else {
                        Self.keyEvent = .RightDragKeyup
                    }
                    
                    if change.translation.height < -delta {
                        Self.keyEvent = .UpDragKeyup
                        Self.keyEvent = .DownDragKeydown
                    } else {
                        Self.keyEvent = .DownDragKeyup
                    }
                    
                    if change.translation.height > delta {
                        Self.keyEvent = .DownDragKeyup
                        Self.keyEvent = .UpDragKeydown
                    } else {
                        Self.keyEvent = .UpDragKeyup
                    }
                    #endif
                }
                .onEnded { _ in
                    touchStart = nil
                    
                    #if os(iOS)
                    Self.keyEvent = .UpDragKeyup
                    Self.keyEvent = .DownDragKeyup
                    Self.keyEvent = .LeftDragKeyup
                    Self.keyEvent = .RightDragKeyup
                    Self.keyEvent = .InDragKeyup
                    Self.keyEvent = .OutDragKeyup
                    #endif
                }
        )
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        MobileAppRootView()
    }
}
#endif
