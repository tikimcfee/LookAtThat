//
//  NumberConversions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/31/22.
//

#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Foundation
import CoreGraphics


extension VectorFloat {
    var toDouble: Double {
        Double(self)
    }
}

extension Double {
    var cg: CGFloat {
        return self
    }
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

extension CGFloat {
    var float: Float {
        return Float(self)
    }
}

extension CGSize {
    var asSimd: LFloat2 {
        LFloat2(width.float, height.float)
    }
}
