//
//  Locations.swift
//  trippa
//
//  Created by haitran on 2/27/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import Foundation
import Photos

enum LocationType: Int {
    case route = 0
    case arrival = 1
    case departure = 2
    
    var description: String {
        return String(describing: self)
    }
}

class Location: NSObject {
    
    var id          : Int
    var uuid        : String
    var cardID      : Int?
    var name        : String
    var country     : String
    var city        : String
    var state       : String
    var longitude   : Double
    var latitude    : Double
    var horizontalAccuracy : Double
    var createdAt   : Date
    var arrivalTime : Date?
    var departureTime : Date?
    var transport   : String?
    var medias      : Array<PHAsset>?
    
    var hasEvent = false
    var density = 0
    var accuracy = 0.0
    
    var isVisit : Bool {
        return self.arrivalTime != nil
    }
    
    var type: LocationType {
        if arrivalTime != nil && departureTime == nil {
            return .arrival
        }
        else if departureTime != nil {
            return .departure
        }
        return .route
    }
    
    var location: CLLocation {
        return CLLocation(coordinate: CLLocationCoordinate2DMake(self.latitude, self.longitude), altitude: 0, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: 0, timestamp: self.createdAt)
    }
    
    func distance(from location: Location) -> Double {
        return self.location.distance(from: location.location)
    }
    
    func duration(from location: Location) -> Double {
        return abs(self.createdAt.timeIntervalSince(location.createdAt))
    }
    
    func transformToRoute() {
        self.arrivalTime = nil
        self.departureTime = nil
    }
    
    init(location: Location) {
        self.id = location.id
        self.uuid = location.uuid
        self.cardID = location.cardID
        self.name = location.name
        self.country = location.country
        self.city = location.city
        self.state = location.state
        self.longitude = location.longitude
        self.latitude = location.latitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.createdAt = location.createdAt
        self.arrivalTime = location.arrivalTime
        self.departureTime = location.departureTime
        self.transport = location.transport
        self.medias = location.medias
    }
    
    override init() {
        id = 0
        uuid = ""
        name = ""
        country = ""
        city = ""
        state = ""
        longitude = 0
        latitude = 0
        createdAt = Date()
        horizontalAccuracy = 0
    }
    
    init(uuid: String, longitude: Double, latitude: Double,horizontalAccuracy: Double, createdAt: Date, arrivalTime: Date? = nil, departureTime: Date? = nil, transport: String? = nil, medias: [PHAsset]? = nil, density : Int = 0) {
        self.id = 0
        self.uuid = uuid
        self.name = ""
        self.country = ""
        self.city = ""
        self.state = ""
        self.longitude = longitude
        self.latitude = latitude
        self.horizontalAccuracy = horizontalAccuracy
        self.createdAt = createdAt
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
        self.transport = transport
        self.medias = medias
        self.density = density
    }
    
}
