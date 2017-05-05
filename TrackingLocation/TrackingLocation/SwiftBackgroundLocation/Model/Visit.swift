//
//  Visit.swift
//  trippa
//
//  Created by dang huu duong on 4/4/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation


public class Visit: NSObject, NSCoding {
    var id: String = ""
    var location: CLLocation
    var mornitorDate: Date
    var createdVisit: Bool = false
    
    init(id: String, location: CLLocation, mornitorDate: Date, createdVisit: Bool) {
        self.id = id
        self.location = location
        self.mornitorDate = mornitorDate
        self.createdVisit = createdVisit
    }
    
    init(location: CLLocation, mornitorDate: Date, createdVisit: Bool? = false) {
        self.location = location
        self.mornitorDate = mornitorDate
        self.createdVisit = createdVisit!
    }
    
    func distanceToLocation(location: CLLocation) -> CLLocationDistance {
        return self.location.distance(from: location)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(location, forKey: "location")
        aCoder.encode(mornitorDate, forKey: "date")
        aCoder.encode(createdVisit, forKey: "created")
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: "id") as! String
        let location = aDecoder.decodeObject(forKey: "location") as! CLLocation
        let mornitorDate = aDecoder.decodeObject(forKey: "date") as! Date
        let createdVisit = aDecoder.decodeBool(forKey: "created")
        self.init(id: id, location: location, mornitorDate: mornitorDate, createdVisit: createdVisit)
    }
}
