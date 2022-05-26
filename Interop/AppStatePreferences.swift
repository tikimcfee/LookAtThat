//
//  AppStatePreferences.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/26/22.
//

import Foundation

class AppStatePreferences {
    private let store = UserDefaults(suiteName: "AppStatePreferences")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    static let shared = AppStatePreferences()
    
    var panelStates: CodableAutoCache<PanelSections, FloatableViewMode>? {
        get {
            _getEncoded("panelStates")
        }
        set {
            _setEncoded(newValue, "panelStates")
        }
    }
    
    var visiblePanels: Set<PanelSections>? {
        get {
            _getEncoded("panelSections")
        }
        set {
            _setEncoded(newValue, "panelSections")
        }
    }
    
    var securedScopeData: (FileBrowser.Scope, Data)? {
        get {
            guard let scope: FileBrowser.Scope = _getEncoded("lastScope"),
                  let data: Data = _getRaw("securedScopeData")
            else { return nil }
            return (scope, data)
        }
        set {
            _setEncoded(newValue?.0, "lastScope")
            _setRaw(newValue?.1, "securedScopeData")
        }
    }
}

private extension AppStatePreferences {
    func _setEncoded<T: Codable>(_ any: T?, _ key: String) {
        print(">>Encoded preference '\(key)' updating to: \(String(describing: any))")
        store?.set(try? encoder.encode(any), forKey: key)
    }
    
    func _getEncoded<T: Codable>(_ key: String) -> T? {
        guard let encoded = store?.object(forKey: key) as? Data else { return nil }
        return try? decoder.decode(T.self, from: encoded)
    }
    
    func _setRaw<T: Codable>(_ any: T?, _ key: String) {
        print(">>Raw preference '\(key)' updating to: \(String(describing: any))")
        store?.set(any, forKey: key)
    }
    
    func _getRaw<T: Codable>(_ key: String) -> T? {
        store?.object(forKey: key) as? T
    }
}
