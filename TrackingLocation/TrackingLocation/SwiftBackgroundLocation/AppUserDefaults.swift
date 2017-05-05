//
//  TrippaUserDefaults.swift
//  trippa
//
//  Created by haitran on 2/10/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import Foundation
import MapKit

public struct Listener<T>: Hashable {
    
    let name: String
    
    public typealias Action = (T) -> Void
    let action: Action
    
    public var hashValue: Int {
        return name.hashValue
    }
}

public func ==<T>(lhs: Listener<T>, rhs: Listener<T>) -> Bool {
    return lhs.name == rhs.name
}

final public class Listenable<T> {
    
    public var value: T {
        didSet {
            setterAction(value)
            
            for listener in listenerSet {
                listener.action(value)
            }
        }
    }
    
    public typealias SetterAction = (T) -> Void
    var setterAction: SetterAction
    
    var listenerSet = Set<Listener<T>>()
    
    public func bindListener(_ name: String, action: @escaping Listener<T>.Action) {
        let listener = Listener(name: name, action: action)
        listenerSet.update(with: listener)
    }
    
    public func bindAndFireListener(_ name: String, action: @escaping Listener<T>.Action) {
        bindListener(name, action: action)
        
        action(value)
    }
    
    public func removeListenerWithName(_ name: String) {
        for listener in listenerSet {
            if listener.name == name {
                listenerSet.remove(listener)
                break
            }
        }
    }
    
    public func removeAllListeners() {
        listenerSet.removeAll(keepingCapacity: false)
    }
    
    public init(_ v: T, setterAction action: @escaping SetterAction) {
        value = v
        setterAction = action
    }
}

final class AppUserDefaults {
    
    struct Keys {
        static let locationWhenLogin = "locationWhenLogin"
        static let usedToFly: String = "usedToFly"
    }
    
    static let defaults = UserDefaults()
    
    public static func saveLocationWhenLogin(location: CLLocation) {
        let data = NSKeyedArchiver.archivedData(withRootObject: location)
        defaults.set(data, forKey: AppUserDefaults.Keys.locationWhenLogin)
        defaults.synchronize()
    }
    
    public static var locationWhenLogin: CLLocation? {
        if let data = defaults.value(forKey: AppUserDefaults.Keys.locationWhenLogin) as? Data {
            if let visitFirstTimeInstallApp = NSKeyedUnarchiver.unarchiveObject(with: data) as? CLLocation {
                return visitFirstTimeInstallApp
            }
            return nil
        }
        return nil
    }
    
    public static func saveUsedToFlyStatus(_ isFly: Bool) {
        defaults.set(isFly, forKey: AppUserDefaults.Keys.usedToFly)
        defaults.synchronize()
    }
    
    public static var isUsedToFly: Bool {
        return defaults.bool(forKey: AppUserDefaults.Keys.usedToFly)
    }
}
