//
//  Config.swift
//  TrackingLocation
//
//  Created by admin on 5/5/17.
//  Copyright © 2017 Si Nguyen. All rights reserved.
//

import UIKit

public struct Config {
    struct LocationService {
        static let maxHorizontalAccuracy = 70.0 // metters
        static let minSpeedLocationTracking = 0.2 // metters per second
        static let minStopTimeinterval = TimeInterval(60*5) // 5 minutes
        static let minTimeIntervalGetVisitWhenLogin = TimeInterval(60*1) // 1 minutes
        static let minLocationTimestampFromNow = TimeInterval(30) // seconds
        static let maxNumberLocationToRecord = 5
        static let regionRadius = 80.0
    }
    
    struct Altimeter {
        static let defaultSeaLevelPressure: Double = 29.92
        static let ratioFeetToMeters: Double = 0.3048
        static let heightDefaultFlying: Double = 1500.0 //meters
        static let heightDefaultNonFlying: Double = 500.0 //meters
        static let differentialAltitude: Double = 100.0 //meters
    }
}

struct Constants {
    static let suitName = "com.swiftbackgroundlocation"
}
