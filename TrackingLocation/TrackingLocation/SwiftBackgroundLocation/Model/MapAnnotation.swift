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
    var isPickOnMap : Bool
    var title : String?
    var subtitle : String?
    var iconURLString: String?
    
    init(title:String? = nil, subTitle:String? = nil,
         coordinate: CLLocationCoordinate2D, isAnnotationPickMap: Bool,
         iconURLString: String? = nil
        ) {
        self.title = title
        self.subtitle = subTitle
        self.coordinate = coordinate
        self.isPickOnMap = isAnnotationPickMap
        self.iconURLString = iconURLString
    }
}
