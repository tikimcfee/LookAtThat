//
//  FocusBoxEngineiOS.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/18/21.
//

import Foundation
import SceneKit

struct FocusBoxEngineiOS: FocusBoxLayoutEngine {
    private let userShim = FocusBoxUserEngineiOS()
    private let defaultShim = FocusBoxDefaultEngineiOS()
    
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        switch container.box.layoutMode {
        case .userStack:
            userShim.onSetBounds(container, newValue)
        case .stacked:
            defaultShim.onSetBounds(container, newValue)
        case .horizontal:
            defaultShim.onSetBounds(container, newValue)
        case .cylinder:
            defaultShim.onSetBounds(container, newValue)
        }
    }
    
    func layout(_ container: FBLEContainer) {
        switch container.box.layoutMode {
        case .userStack:
            userShim.layout(container)
        case .stacked:
            defaultShim.layout(container)
        case .horizontal:
            defaultShim.layout(container)
        case .cylinder:
            defaultShim.layout(container)
        }
    }
}

// MARK: - Standard Layout

private struct FocusBoxDefaultEngineiOS: FocusBoxLayoutEngine {
    let xLengthPadding: VectorFloat = 8.0 * DeviceScale
    let zLengthPadding: VectorFloat = 150.0 * DeviceScale
    
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        defaultOnSetBounds(container, newValue)
    }
    
    func layout(_ container: FBLEContainer) {
        sceneTransaction {
            switch container.box.layoutMode {
            case .horizontal:
                horizontalLayout(container)
            case .stacked:
                stackLayout(container)
            case .userStack:
                print("ERROR - iOS user stack in the wrong engine!")
            case .cylinder:
                defaultCylinderLayout(container)
            }
        }
    }
    
    func horizontalLayout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
        container.box.snapping.iterateOver(first, direction: .right) { previous, current, _ in
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
    
    func stackLayout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
        container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
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

// MARK: - User Layout

private struct FocusBoxUserEngineiOS: FocusBoxLayoutEngine {
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        defaultOnSetBounds(container, newValue)
    }
    
    func layout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
    
        let zLengthPadding: VectorFloat = 8.0 * DeviceScale
        
        container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
            if let previous = previous {
                current.measures
                    .setTop(previous.measures.top - previous.measures.lengthY / 2.0 + current.measures.lengthY / 2.0)
                    .alignedCenterX(previous)
                    .setFront(previous.measures.back - zLengthPadding)
            } else {
                current.zeroedPosition()
            }
        }
    }
}
