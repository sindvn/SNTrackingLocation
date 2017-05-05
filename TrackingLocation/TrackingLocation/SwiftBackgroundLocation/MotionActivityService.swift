//
//  MotionActivityService.swift
//  trippa
//
//  Created by haitran on 2/24/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import Foundation
import CoreMotion

protocol MotionActivityServiceDelegate : class {
    func retrieveaAtivity(_ activity : Activity)
    func flyingInTheSky(_ isFlying: Bool)
}

class MotionActivityService {
    
    var activityState: Bool = false
    var activity: Activity?
    var altitudeMeters: Double?
    private var isFlying = false
    
    weak var delegate : MotionActivityServiceDelegate?
    private let motionActivityManager: CMMotionActivityManager
    private let altimeter: CMAltimeter
    
    init() {
        self.motionActivityManager = CMMotionActivityManager()
        self.altimeter = CMAltimeter()
        
    }
    
    func start(){
        if(CMMotionActivityManager.isActivityAvailable()){
            self.motionActivityManager.startActivityUpdates(to : OperationQueue.main, withHandler: { data in
                guard let data = data else { return }
                self.activity = Activity(motionActivity: data)
                guard let activity = self.activity else { return }
                self.delegate?.retrieveaAtivity(activity)
            })
        }
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { [weak self] (altitudeData, error) in
                if let altitudeData = altitudeData {
                    let pressureInHg = (altitudeData.pressure.doubleValue) * 0.295301
                    let altitudeFeets = 1000 * (Config.Altimeter.defaultSeaLevelPressure - pressureInHg)
                    self?.altitudeMeters = Config.Altimeter.ratioFeetToMeters * altitudeFeets
                    self?.saveFlyingStatus()
                }
            })
        }
    }
    
    func parseWalkingData(_ activities: [CMMotionActivity]?) -> [Activity]? {
        guard let activities = activities else {
            return nil
        }
        
        var activitiesList = [Activity]()
        var act: Activity?
        var isStartOver = true
        
        for activity in activities {
            if activity.walking && isStartOver {
                act = Activity(motionActivity: activity)
                isStartOver = false
            }
            else if !activity.walking {
                let newAct = Activity(motionActivity: activity)
                
                if let _act = act {
                    let nAct = _act.updateActivityEndDateFrom(activity: newAct)
                    activitiesList.append(nAct)
                    act = nil
                }
                
                isStartOver = true
            }
        }
        
        return activitiesList
    }
    
    func saveFlyingStatus() {
        if let altitudeMeters = self.altitudeMeters {
            if altitudeMeters >= Config.Altimeter.heightDefaultFlying {
                if AppUserDefaults.isUsedToFly == false {
                    AppUserDefaults.saveUsedToFlyStatus(true)
                }
                if isFlying == false {
                    isFlying = true
                    self.delegate?.flyingInTheSky(true)
                }
            }
            else if altitudeMeters < Config.Altimeter.heightDefaultNonFlying {
                if isFlying == true {
                    isFlying = false
                    self.delegate?.flyingInTheSky(false)
                }
            }
        }
    }
    
    public func stopDeviceActivityUpdates() {
        self.motionActivityManager.stopActivityUpdates()
        self.altimeter.stopRelativeAltitudeUpdates()
    }
}
