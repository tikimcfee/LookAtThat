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
    
    enum Key: String {
        case panelStates
        case panelSections
        
        case lastScope
        case securedScopeData
    }
    
    var panelStates: CodableAutoCache<PanelSections, FloatableViewMode>? {
        get { _getEncoded(.panelStates) }
        set { _setEncoded(newValue, .panelStates) }
    }
    
    var visiblePanels: Set<PanelSections>? {
        get { _getEncoded(.panelSections) }
        set { _setEncoded(newValue, .panelSections) }
    }
    
    var securedScopeData: PeristedSecureScope? {
        get { getPersistedSecureScope() }
        set { setPersistedSecureScope(newValue) }
    }
}

typealias PeristedSecureScope = (FileBrowser.Scope, Data)
private extension AppStatePreferences {
    func getPersistedSecureScope() -> PeristedSecureScope? {
        guard let scope: FileBrowser.Scope = _getEncoded(.lastScope),
              let data: Data = _getRaw(.securedScopeData)
        else { return nil }
        return (scope, data)
    }
    
    func setPersistedSecureScope(_ newValue: PeristedSecureScope?) {
        _setEncoded(newValue?.0, .lastScope)
        _setRaw(newValue?.1, .securedScopeData)
    }
}

private extension AppStatePreferences {
    func _setEncoded<T: Codable>(_ any: T?, _ key: Key) {
        print(">>Updating Encoded preference '\(key)'")
        store?.set(try? encoder.encode(any), forKey: key.rawValue)
    }
    
    func _getEncoded<T: Codable>(_ key: Key) -> T? {
        guard let encoded = store?.object(forKey: key.rawValue) as? Data else { return nil }
        return try? decoder.decode(T.self, from: encoded)
    }
    
    func _setRaw<T: Codable>(_ any: T?, _ key: Key) {
        print(">> Updating Raw preference '\(key)'")
        store?.set(any, forKey: key.rawValue)
    }
    
    func _getRaw<T: Codable>(_ key: Key) -> T? {
        store?.object(forKey: key.rawValue) as? T
    }
}

