import Foundation

class LeapMotionManager: NSObject, LeapDelegate {

    static let sharedInstance = LeapMotionManager()

    let controller = LeapController()
    var rightHandPosition = LeapVector()
    var leftHandPosition = LeapVector()

    func run() {
        controller?.addDelegate(self)
        print("running")
    }

    // MARK: - LeapDelegate Methods

    func onInit(_ controller: LeapController!) {
        print("initialized")
    }

    func onConnect(_ controller: LeapController!) {
        print("connected")
        controller.enable(LEAP_GESTURE_TYPE_CIRCLE, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_KEY_TAP, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_SCREEN_TAP, enable: true)
        controller.enable(LEAP_GESTURE_TYPE_SWIPE, enable: true)
    }

    func onDisconnect(_ controller: LeapController!) {
        print("disconnected")
    }

    func onServiceConnect(_ controller: LeapController!) {
        print("service disconnected")
    }

    func onDeviceChange(_ controller: LeapController!) {
        print("device changed")
    }

    func onExit(_ controller: LeapController!) {
        print("exited")
    }

    func onFrame(_ controller: LeapController!) {
        let currentFrame = controller.frame(0) as LeapFrame
        let hands = currentFrame.hands as! [LeapHand]
        for hand in hands {
            if hand.isLeft {
                leftHandPosition = hand.palmPosition
                print("left hand position: \(leftHandPosition)")
            } else if hand.isRight {
                rightHandPosition = hand.palmPosition
                print("right hand position: \(rightHandPosition)")
            }
        }
    }

    func onFocusGained(_ controller: LeapController!) {
        print("focus gained")
    }

    func onFocusLost(_ controller: LeapController!) {
        print("focus lost")
    }

}
