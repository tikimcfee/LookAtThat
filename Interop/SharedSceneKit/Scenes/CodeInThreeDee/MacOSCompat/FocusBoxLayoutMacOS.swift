//
//  FocusBoxLayoutMacOS.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/18/21.
//

import Foundation

class FocusBoxLayoutMacOS: FocusBoxLayoutEngine {
    func layout(_ box: FocusBox) {
        guard let first = box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
        let xLengthPadding: VectorFloat = 8.0
        let zLengthPadding: VectorFloat = 150.0
        
        sceneTransaction {
            switch box.layoutMode {
            case .horizontal:
                horizontalLayout()
            case .stacked:
                stackLayout()
            }
        }
        
        func horizontalLayout() {
            box.snapping.iterateOver(first, direction: .right) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .setLeading(previous.measures.trailing + xLengthPadding)
                        .setBack(previous.measures.back)
                } else {
                    current.zeroedPosition()
                }
            }
        }
        
        func stackLayout() {
            box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .alignedCenterX(previous)
                        .setBack(previous.measures.back - zLengthPadding)
                } else {
                    current.zeroedPosition()
                }
            }
        }
    }
}
