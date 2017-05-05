//
//  Config.swift
//  TrackingLocation
//
//  Created by admin on 5/5/17.
//  Copyright © 2017 Si Nguyen. All rights reserved.
//

import UIKit

class Config: NSObject {
    struct LocationService {
        static let maxHorizontalAccuracy = 100.0 // metters
        //        static let minHorizontalAccuracy = 20.0 // metters
        static let minSpeedLocationTracking = 0.2 // metters per second
        static let minStopTimeinterval = TimeInterval(60*5) // 5 minutes
        static let minTimeIntervalGetVisitWhenLogin = TimeInterval(60*1) // 1 minutes
        static let minLocationTimestampFromNow = TimeInterval(30) // seconds
        static let maxNumberLocationToRecord = 10
    }
    
    struct Altimeter {
        static let defaultSeaLevelPressure: Double = 29.92
        static let ratioFeetToMeters: Double = 0.3048
        static let heightDefaultFlying: Double = 1500.0 //meters
        static let heightDefaultNonFlying: Double = 500.0 //meters
    }
}

struct Constants {
    static let suitName = "com.swiftbackgroundlocation"
}
