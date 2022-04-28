//
//  Finguhs.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 4/17/22.
//

import SwiftUI

class TapObserving: ObservableObject {
    
    private(set) static var shared = TapObserving()
    
    @Published var fingers: [Fingers] = []
    
    private lazy var delegate = StartingTapDelegate()
    
    func start() {
        delegate.tapUpdates = { [weak self] fingers in
            self?.enqueueUpdate(fingers)
        }
        TAPKit.sharedKit.addDelegate(delegate)
        TAPKit.sharedKit.start()
    }
    
    func stop() {
        delegate.tapUpdates = nil
        TAPKit.sharedKit.removeDelegate(delegate)
    }
    
    private func enqueueUpdate(_ fingers: [Fingers]) {
        DispatchQueue.main.async {
            self.fingers = fingers
        }
    }
}

struct FingerSUI: View {
    @EnvironmentObject var observing: TapObserving
    
    var body: some View {
        VStack {
            allFingers
        }
        .padding(8.0)
    }
    
    var allFingers: some View {
        HStack(alignment: .center) {
            ForEach(Fingers.allCases, id: \.rawSensorID) { finger in
                FingerButton(
                    finger: finger,
                    found: observing.fingers.contains(finger)
                )
            }
        }
    }
}

struct FingerButton: View {
    let finger: Fingers
    let found: Bool
    var color: Color { found ? Color.green : Color.red }
    
    var body: some View {
        Text(finger.description)
            .foregroundColor(.white)
            .frame(width: 56.0, height: 32.0, alignment: .center)
            .border(.white, width: 2.0)
            .background(color)
            
    }
}

struct FingerSUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FingerSUI()
                .environmentObject(TapObserving.shared)
        }
    }
}
