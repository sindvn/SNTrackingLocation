//
//  LocationFilter.swift
//  trippa
//
//  Created by Tuan Truong on 4/12/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import UIKit

protocol LocationFilterProtocol {
    func filter(_ locations: [Location]) -> (locations: [Location], stopPoints: [Location])
}

class LocationFilter: LocationFilterProtocol {
    func filter(_ locations: [Location]) -> (locations: [Location], stopPoints: [Location]) {
        guard locations.count > 0 else {
            return ([],[])
        }
        
        let locations = preprocessing(locations)
        
        let distanceThreshold: Double = 80   // default is 80
        let durationThreadhold: Double = 6 * 60
        
        var stopPoints = [LocationCluster]()
        var route = [Location]()
        var tempRoute = [Location]()
        var currentCluster = LocationCluster()
        
        func addToStopPoints(cluster: LocationCluster) -> Bool {
            if let lastSP = stopPoints.last, lastSP.distance(from: cluster) < distanceThreshold {
                lastSP.merge(cluster)
                return false
            }
            else {
                stopPoints.append(cluster)
                return true
            }
        }
        
        for location in locations {
            
            if currentCluster.distance(from: location) < distanceThreshold {
                currentCluster.add(location)   // type 2
            }
            else {  // currentCluster.distance(from: location) >= distanceThreshold
                if currentCluster.duration > durationThreadhold {
                    
                    if addToStopPoints(cluster: currentCluster) {
                        route.append(contentsOf: tempRoute)
                    }
                    tempRoute = []
                }
                else { // currentCluster.duration < durationThreadhold
                    
                    // check if current cluster is card
                    if currentCluster.hasEvent {
                        if addToStopPoints(cluster: currentCluster) {
                            route.append(contentsOf: tempRoute)
                        }
                        tempRoute = []
                    }
                    else { // or route
                        if let clusterLocation = currentCluster.location {
                            clusterLocation.transformToRoute()
                            tempRoute.append(clusterLocation)
                        }
                    }
                }
                
                
                // create a new location cluster
                currentCluster = LocationCluster(locations: [location])
                currentCluster.type = .type2
            }
            
        }
        
        // check current location to extract card and route
        if currentCluster.duration > durationThreadhold || currentCluster.hasEvent {
            if addToStopPoints(cluster: currentCluster) {
                route.append(contentsOf: tempRoute)
            }
        }
        else {
            route.append(contentsOf: tempRoute)
            if let clusterLocation = currentCluster.location {
                clusterLocation.transformToRoute()
                route.append(clusterLocation)
            }
        }
        
        // extract center location of location cluster
        let locationsFromStopPoints = stopPoints.flatMap { (cluster) -> Location? in
            return cluster.location
        }
        
        // merge location clusters' center into route
        route.append(contentsOf: locationsFromStopPoints)
        
        route.sort{ $0.createdAt < $1.createdAt }
        
        route = processLocationsByAccuracy(locations: route)
        
        // check
        
        // if last location is from location cluster that does not contain arrival or departure locations
        if let last = route.last, last.type != .route, !last.hasEvent {
            last.departureTime = nil
        }
        
        return (route, locationsFromStopPoints)
    }
    
    private func preprocessing(_ locations: [Location]) -> [Location] {
        guard locations.count > 0 else {
            return []
        }
        
        var result = [Location]()
        var previous = locations[0]
        result.append(previous)
        
        let walkingThreshold = 2.0 // = 7km/h
        let cyclingThreshold = 14.0 // = 50km/h
        let accuracyThreshold = 50.0
        
        for i in 1..<locations.count {
            let location = locations[i]
            if location.type != .route {
                result.append(location)
                previous = location
                continue
            }
            
            // horizontalAccuracy: a negative value indicates that the location’s latitude and longitude are invalid.
            if location.horizontalAccuracy > accuracyThreshold || location.horizontalAccuracy < 0 {
                continue
            }
            let velocity = location.distance(from: previous)/location.duration(from: previous)
            
            var velocityThreshold: Double
            let transit = location.transport ?? ""
            
            switch transit {
            case "walking":
                velocityThreshold = walkingThreshold
            case "cycling":
                velocityThreshold = cyclingThreshold
            default:
                velocityThreshold = -1
            }
            
            if velocityThreshold < 0 || velocity < velocityThreshold {
                result.append(location)
                previous = location
            }
        }
        
        result.sort{ $0.createdAt < $1.createdAt }
        
        return result
    }
    
    // Filter multicard in building
    // - First card is always considered to be valid
    // - Cards that have accuracy < threshold (or route's accuracy < threshold) are considered to be valid
    // - Others are invalid and will be ignored
    
    private func processLocationsByAccuracy(locations: [Location]) -> [Location] {
        guard locations.count > 0 else {
            return []
        }
        var result = [Location]()
        let accuracyThreshold = 20.0  // outdoor locations are always have accuracy < 20
        var previousCard: Location?
        var tempRoute = [Location]()
        
        func isTempRouteAccurate() -> Bool {
            if previousCard == nil { // first card is always valid
                return true
            }
            if tempRoute.count == 0 {
                return false
            }
            
            return tempRoute.min{ $0.accuracy < $1.accuracy }!.accuracy < accuracyThreshold
        }
        
        for location in locations {
            if location.type == .route {
                tempRoute.append(location)
            } else { // location is card
                if location.accuracy < accuracyThreshold
                    || isTempRouteAccurate()
                    || (previousCard != nil && previousCard!.distance(from: location) > 2000) {
                    // card is accurate -> valid
                    result.append(contentsOf: tempRoute)
                    result.append(location)
                    previousCard = location
                } else {
                    // card is not accurate enough -> ignore
                    // reconfig previous card if need
                    if location.type == .arrival {
                        previousCard?.departureTime = nil
                    }
                }
                tempRoute = []
            }
        }
        result.append(contentsOf: tempRoute)
        
        return result
    }
    
}
