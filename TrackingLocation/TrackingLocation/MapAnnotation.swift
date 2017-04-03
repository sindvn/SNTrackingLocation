//
//  MapAnnotation.swift
//  trippa
//
//  Created by admin on 2/23/17.
//  Copyright © 2017 framgia. All rights reserved.
//

import UIKit
import MapKit

class MapAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var title : String?
    
    init(title:String? = nil, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }
}
