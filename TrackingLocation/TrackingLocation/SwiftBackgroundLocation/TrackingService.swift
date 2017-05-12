//
//  TrackingService.swift
//  trippa
//
//  Created by haitran on 2/24/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import Foundation
import CoreLocation
import Photos

protocol TrackingServiceDelegate : class {
    
    func didArrivalLocation(_ location: CLLocation, arrivalDate: Date)
    func didDepartLocation(_ location: CLLocation, arrivalDate : Date, departureDate : Date)
    func didUpdateBackgroundLocation(_ location: CLLocation)
    func didUpdateTrackingLocation(_ location: CLLocation)
}

class TrackingService : NSObject {
    
    static let shared = TrackingService()
    fileprivate let motionActivity : MotionActivityService
    let visitLocationManager : VisitLocationManager
    var visitLogger = VisitLogger()
    fileprivate var visitLocation : Visit?
    
    fileprivate var locationsTracking = [CLLocation]()
    
    weak var delegate: TrackingServiceDelegate?
    
    var maxNumberLocationToRecord: Int {
        if self.visitLocation == nil {
            return Config.LocationService.maxNumberLocationToRecord
        } else {
            return 1
        }
    }
    
    override init() {
        self.motionActivity = MotionActivityService()
        self.visitLocationManager = VisitLocationManager()
        if let visit = visitLogger.readVisit() {
            visitLocation = visit
            visitLocationManager.setArrivalLocation(location: visit.location)
        }
        super.init()
        self.motionActivity.delegate = self
        self.visitLocationManager.delegate = self
    }
    
    func setVisit(for location: CLLocation?) {
        if let location = location {
            let uuid = NSUUID().uuidString
            let visit = Visit(id: uuid, location: location, mornitorDate: location.timestamp, createdVisit: true)
            visitLogger.writeVisitToFile(visit: visit)
            visitLocationManager.setArrivalLocation(location: visit.location)
            visitLocation = visit
        } else {
            visitLogger.removeLogFile()
            visitLocationManager.setArrivalLocation(location: nil)
            visitLocation = nil
        }
    }
    
    func start() {
        self.motionActivity.start()
        self.visitLocationManager.startTracking()
    }
    
    func stop() {
        self.motionActivity.stopDeviceActivityUpdates()
        self.visitLocationManager.stopTracking()
    }
    
    func cleanData() {
        visitLogger.removeLogFile()
        visitLocation = nil
        locationsTracking.removeAll()
        self.visitLocationManager.cleanData()
    }
   
    fileprivate func recordLocation(uuid : String, location: CLLocation, arrivalTime: Date? = nil, departureTime : Date? = nil) {
        var activityTypeDescription: String?
        if AppUserDefaults.isUsedToFly {
            activityTypeDescription = TrippaActivityType.airplane.rawValue
            AppUserDefaults.saveUsedToFlyStatus(false)
            visitLocationManager.saveDepartWhenFlying()
        } else {
            activityTypeDescription = self.motionActivity.activity?.type.description
        }
        let locationData = Location(uuid : uuid,
                                    longitude: location.coordinate.longitude,
                                    latitude: location.coordinate.latitude,
                                    horizontalAccuracy: location.horizontalAccuracy,
                                    createdAt: location.timestamp,
                                    arrivalTime: arrivalTime,
                                    departureTime: departureTime,
                                    transport: activityTypeDescription,
                                    medias: nil)
        //create(locationData)
    }
    
    fileprivate func updateLocation(uuid: String, arrivalTime : Date, departureTime : Date) {
        //update(byUUID: uuid, departureTime: departureTime)
    }
    
    fileprivate func getBestLocationFromLocationArray() -> CLLocation? {
        if let location = locationsTracking.min(by: { (l1, l2) -> Bool in
            return l1.horizontalAccuracy < l2.horizontalAccuracy}) {
            return location
        }
        return nil
    }
}

extension TrackingService : MotionActivityServiceDelegate {
    func retrieveaAtivity(_ activity : Activity) {
        
    }
    
    func flyingInTheSky(_ isFlying: Bool) {
        visitLocationManager.isFlying = isFlying
    }
}

extension TrackingService : VisitLocationManagerDelegate {
    
    func didUpdateTrackingLocation(_ location: CLLocation) {
        
        if let lastLocation = locationsTracking.last { // if location array exist get last location to compare with new location
            
            // if reach max location cache or distance beetween 2 point is far we record best location in array
            if lastLocation.distance(from: location) > 50
                || locationsTracking.count >= maxNumberLocationToRecord {
                if let bestLocation = getBestLocationFromLocationArray() {
                    self.recordLocation(uuid: NSUUID().uuidString, location: bestLocation)
                    
                    // Local map
                    self.delegate?.didUpdateTrackingLocation(bestLocation)
                }
                locationsTracking = [location]
            }
            else {
                locationsTracking.append(location)
            }
        }
        else {
            locationsTracking.append(location)
        }
    }
    
    
    func didUpdateBackgroundLocation(_ location: CLLocation) {
        self.delegate?.didUpdateBackgroundLocation(location)
    }
    
    func didDepartLocation(_ location: CLLocation, arrivalDate: Date, departureDate: Date) {
        self.delegate?.didDepartLocation(location, arrivalDate: arrivalDate, departureDate: departureDate)
        
        var uuid = NSUUID().uuidString
        if let visit = visitLocation {
            uuid = visit.id
            visitLocation = nil
            visitLogger.removeLogFile()
        }
        // if uuid invalid (deleted when sync card, app suspend...)
        // -> update departTime in cardInvalid
        self.updateLocation(uuid: uuid, arrivalTime: arrivalDate, departureTime: departureDate)
    }
    
    func didArrivalLocationWhenLogin(_ location: CLLocation, arrivalDate: Date) {
        self.didArrivalLocation(location, arrivalDate: arrivalDate)
    }
    
    func didArrivalLocation(_ location: CLLocation, arrivalDate : Date) {
        self.delegate?.didArrivalLocation(location, arrivalDate: arrivalDate)
        let uuid = NSUUID().uuidString
        let visit = Visit(id: uuid, location: location, mornitorDate: arrivalDate, createdVisit: true)
        visitLocation = visit
        visitLogger.writeVisitToFile(visit: visit)
        
        self.recordLocation(uuid: uuid, location: location, arrivalTime: arrivalDate, departureTime: nil)
    }
}

