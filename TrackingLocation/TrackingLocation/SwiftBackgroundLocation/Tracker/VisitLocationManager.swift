//
//  VisitLocationManager.swift
//  trippa
//
//  Created by admin on 4/11/17.
//  Copyright © 2017 framgia. All rights reserved.
//
import UIKit
import CoreLocation

protocol VisitLocationManagerDelegate : class {
    func didArrivalLocationWhenLogin(_ location: CLLocation, arrivalDate: Date)
    func didArrivalLocation(_ location: CLLocation, arrivalDate: Date)
    func didDepartLocation(_ location: CLLocation, arrivalDate : Date, departureDate : Date)
    func didUpdateBackgroundLocation(_ location: CLLocation)
    func didUpdateTrackingLocation(_ location: CLLocation)
}

class VisitLocationManager: NSObject {
    
    weak var delegate: VisitLocationManagerDelegate?
    
    let locationManager : TrackingLocationManager
    
    private var regionLocation : CLLocation? {
        didSet {
            if let location = self.regionLocation {
                self.delegate?.didUpdateBackgroundLocation(location)
            }
        }
    }
    
    fileprivate var visitLocation : CLLocation? {
        didSet {
            if let visitLocation = self.visitLocation { // already arrived, tracking departure
                self.locationManager.setPeriodicallyUpdateLocation(outdoor: visitLocation.horizontalAccuracy < 11)
            } else {  // log route and tracking arrival
                self.locationManager.setAlwaysUpdateLocation()
            }
        }
    }
    
    var isFlying = false {
        didSet {
            if isFlying == true {
                saveDepartWhenFlying()
                self.locationManager.setUpdateLocationEachHundredKilometers()
            }
            else {
                self.locationManager.setAlwaysUpdateLocation()
            }
        }
    }
    
    override init() {
        self.locationManager = TrackingLocationManager()
    }
    
    func setArrivalLocation(location : CLLocation?) {
        self.visitLocation = location
        if let location = location {
            regionLocation = location
        }
    }
    
    func startTracking() {
        self.locationManager.delegate = self
        self.locationManager.start {[unowned self] result in
            if case let .Success(location) = result {
                self.updateLocation(location: location)
            }
        }
    }
    
    func stopTracking() {
        self.locationManager.stop()
    }
    
    func cleanData() {
        regionLocation = nil
        visitLocation = nil
    }
    
    func restartTracking() {
        regionLocation = nil
        self.stopTracking()
        self.startTracking()
    }
    
    func saveDepartWhenFlying() {
        if isFlying == true,let visit = visitLocation {
            // update departureDate for previous visit when flying and can't get gps
            self.delegate?.didDepartLocation(visit, arrivalDate: visit.timestamp, departureDate: Date())
            visitLocation = nil
        }
    }
    
    private func updateLocation(location: CLLocation) {
        
        func recordRoute() {
            // only record route when app is tracking new arrival
            if visitLocation == nil {
                self.delegate?.didUpdateTrackingLocation(location)
            }
        }
        
        guard let region = regionLocation else {
            regionLocation = location
            recordRoute()
            return
        }
        
        // compare region with location tracking if distance > regionRadius -> get new region
        // if cannot get new region (background region not update)
        // -> user out region with distance > regionRadius*2 -> try to restart background manager to get new region
        if region.distance(from: location) > Config.LocationService.regionRadius {
            
            if region.distance(from: location) > Config.LocationService.regionRadius * 2 {
                // restart background manager when it may be stop tracking
                self.restartTracking()
            }
            else {
                regionLocation = location
            }
            
            if let visit = visitLocation {
                
                self.delegate?.didDepartLocation(visit, arrivalDate: visit.timestamp, departureDate: location.timestamp)
                
                visitLocation = nil
            }
        }
        else if AppUserDefaults.locationWhenLogin == nil {
            // use when login
            // get a visit location after 1 minute
            // server will reject if duplicate visit
            
            let time = location.timestamp.timeIntervalSince(region.timestamp)
            
            if time > (Config.LocationService.minTimeIntervalGetVisitWhenLogin)  {
                
                AppUserDefaults.saveLocationWhenLogin(location: region)
                visitLocation = region
                self.delegate?.didArrivalLocationWhenLogin(region, arrivalDate: region.timestamp)
            }
        }
        else if visitLocation == nil {
            
            let time = location.timestamp.timeIntervalSince(region.timestamp)
            
            if time > (Config.LocationService.minStopTimeinterval)  {
                // user can move 10-15m in region after that he stop
                // long-lat will be location
                // arrival time will be time in region
                visitLocation = CLLocation(coordinate: location.coordinate,
                                           altitude: location.altitude,
                                           horizontalAccuracy: location.horizontalAccuracy,
                                           verticalAccuracy: location.verticalAccuracy,
                                           timestamp: region.timestamp)
                self.delegate?.didArrivalLocation(location, arrivalDate: region.timestamp)
                
                regionLocation = location
            }
        }
        
        recordRoute()
    }
}

// MARK: - TrackingLocationManagerDelegate
extension VisitLocationManager: TrackingLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            // nothing
        } else {
            if let visit = visitLocation {
                self.delegate?.didDepartLocation(visit, arrivalDate: visit.timestamp, departureDate: Date())
            }
            visitLocation = nil
        }
    }
}
