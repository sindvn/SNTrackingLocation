//
//  Activity.swift
//  TrackingLocation
//
//  Created by admin on 5/5/17.
//  Copyright © 2017 Si Nguyen. All rights reserved.
//

import UIKit
import CoreMotion

enum ActivityType {
    case stationary
    case walking
    case running
    case cycling
    case automotive
    case other
    
    var description: String {
        return String(describing: self)
    }
}

enum TrippaActivityType: String {
    case walking
    case cycling
    case vehicle
    case airplane
    case other
    
    var description: String {
        return String(describing: self)
    }
}

struct Activity {
    let type: TrippaActivityType
    let startDate: Date
    let endDate: Date
    var isStationary: Bool
    
    init(type: TrippaActivityType, startDate: Date, endDate: Date) {
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.isStationary = false
    }
    
    init(motionActivity: CMMotionActivity) {
        self.init(motionActivity: motionActivity, altitudeFeet: nil)
    }
    
    init(motionActivity: CMMotionActivity, altitudeFeet: Double?) {
        isStationary = false
        if motionActivity.stationary {
            isStationary = true
            type = .walking
        } else if motionActivity.walking {
            type = .walking
        } else if motionActivity.running {
            type = .walking
        } else if motionActivity.cycling {
            type = .cycling
        } else if motionActivity.automotive {
            type = .vehicle
        }
        else {
            type = .other
        }
        startDate = motionActivity.startDate as Date
        endDate = motionActivity.startDate as Date
    }
    
    init(activity: Activity, newEndDate: Date) {
        type = activity.type
        startDate = activity.startDate
        endDate = newEndDate
        isStationary = false
    }
    
    func updateActivityEndDateFrom(activity: Activity) -> Activity {
        return Activity(activity: self, newEndDate: activity.endDate)
    }
    
}
