//
//  LocationCluster.swift
//  trippa
//
//  Created by Tuan Truong on 4/12/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import UIKit
import CoreLocation

enum LocationClusterType {
    case type1
    case type2
    case type3
}

class LocationCluster {
    var locations: [Location]
    var type: LocationClusterType
    
    var numberOfLocations: Int {
        return locations.count
    }
    
    private var _location: Location?
    
    var location: Location? {
        if _location != nil {
            return _location!
        }
        let result: Location?
        
        if numberOfLocations == 0 {
            result = nil
        }
        else if numberOfLocations == 1 {
            result = locations[0]
            result?.density = 1
            result?.accuracy = result?.horizontalAccuracy ?? 0
        }
        else {
            if let arrivalTime = self.arrivalTime {
                result = Location(location: self.centerLocation)
                result?.arrivalTime = arrivalTime
                result?.departureTime = self.departureTime
                result?.createdAt = arrivalTime
                
                // if locations contain any arrival or departure
                result?.hasEvent = self.hasEvent
                result?.accuracy = self.accuracy
                result?.density = numberOfLocations
                
                if locations.contains(where: { $0.transport == "airplane" }) {
                    result?.transport = "airplane"
                }
            }
            else {
                result = nil
            }
        }
        
        _location = result
        
        return result
    }
    
    private var _centroid: CLLocation?
    
    var centroid: CLLocation {
        if _centroid != nil {
            return _centroid!
        }
        let result: CLLocation
        
        if locations.count == 0 {
            result = CLLocation()
        } else if locations.count == 1 {
            result = locations[0].location
        }
        else {
            if let location = locations.first(where: { $0.type != .route }) {
                result = location.location
            } else {
                let centroidLat = locations.reduce(0, { (result, location) -> Double in
                    return result + location.latitude
                })
                let centroidLng = locations.reduce(0, { (result, location) -> Double in
                    return result + location.longitude
                })
                result = CLLocation(latitude: centroidLat/Double(locations.count), longitude: centroidLng/Double(locations.count))
            }
        }
        
        _centroid = result
        return result
    }
    
    private var _centerLocation: Location?
    
    // Return the location that is nearest centroid
    var centerLocation: Location {
        if _centerLocation != nil {
            return _centerLocation!
        }
        
        var center = self.centroid
        if let location = locations.first(where: { $0.type != .route }) {
            let processedLocations = locations.filter { $0.horizontalAccuracy < 35 && $0.distance(from: location) < 40 }
            if processedLocations.count > 0 {
                let centroidLat = processedLocations.reduce(0, { (result, location) -> Double in
                    return result + location.latitude
                })
                let centroidLng = processedLocations.reduce(0, { (result, location) -> Double in
                    return result + location.longitude
                })
                center = CLLocation(latitude: centroidLat/Double(processedLocations.count),
                                    longitude: centroidLng/Double(processedLocations.count))
            }
        }
        var index = 0
        
        for i in 1..<locations.count {
            if locations[i].location.distance(from: center) < locations[index].location.distance(from: center) {
                index = i
            }
        }
        _centerLocation = locations[index]
        
        return _centerLocation!
    }
    private var _duration: TimeInterval?
    
    var duration: TimeInterval {
        if _duration != nil {
            return _duration!
        }
        let result: TimeInterval
        
        if numberOfLocations < 2 {
            result = 0
        }
        else {
            var duration = 0.0
            for i in 1..<locations.count {
                duration += locations[i].duration(from: locations[i-1])
            }
            result = duration
        }
        
        _duration = result
        return result
    }
    
    private var _arrivalTime: Date?
    
    var arrivalTime: Date? {
        if _arrivalTime != nil {
            return _arrivalTime!
        }
        var result: Date?
        let arrivalLocations = self.locations.filter { $0.type != .route }
        if let first = arrivalLocations.first {
            result = first.arrivalTime
        }
        else {
            result = locations.min { $0.createdAt < $1.createdAt }?.createdAt
        }
        _arrivalTime = result
        return result
    }
    
    private var _departureTime: Date?
    
    var departureTime: Date? {
        if _departureTime != nil {
            return _departureTime!
        }
        var result: Date?
        let departureLocations = self.locations.filter { $0.type != .route }
        if let last = departureLocations.last {
            result = last.departureTime
        }
        else {
            result = locations.max { $0.createdAt < $1.createdAt }?.createdAt
        }
        _departureTime = result
        return result
    }
    
    var hasEvent: Bool {
        if locations.contains(where: { $0.type != .route }) {
            return true
        }
        return false
    }
    
    var accuracy: Double {
        if let min = locations.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) {
            return min.horizontalAccuracy
        }
        return 0
    }
    
    init() {
        locations = [Location]()
        type = LocationClusterType.type1
    }
    
    init(locations: [Location]) {
        self.locations = locations
        type = LocationClusterType.type1
    }
    
    func add(_ location: Location) {
        locations.append(location)
        resetLocalData()
    }
    
    func add(_ locations: [Location]) {
        self.locations.append(contentsOf: locations)
        resetLocalData()
    }
    
    func distance(from location: Location) -> Double {
        switch self.numberOfLocations {
        case 0:
            return 0.0
        case 1:
            return self.locations[0].distance(from: location)
        default:
            return self.centroid.distance(from: location.location)
        }
    }
    
    func distance(from cluster: LocationCluster) -> Double {
        guard self.numberOfLocations > 0 && cluster.numberOfLocations > 0 else {
            return 0.0
        }
        
        return self.centroid.distance(from: cluster.centroid)
    }
    
    func duration(from cluster: LocationCluster) -> Double {
        guard let departure1 = cluster.departureTime,
            let arrival2 = self.arrivalTime,
            departure1 < arrival2 else {
                return 0.0
        }
        return arrival2.timeIntervalSince(departure1)
    }
    
    func merge(_ cluster: LocationCluster) {
        locations.append(contentsOf: cluster.locations)
        resetLocalData()
    }
    
    private func resetLocalData() {
        _location = nil
        _centroid = nil
        _centerLocation = nil
        _duration = nil
        _arrivalTime = nil
        _departureTime = nil
    }
}
