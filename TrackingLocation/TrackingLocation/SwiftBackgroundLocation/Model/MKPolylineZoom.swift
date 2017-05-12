//
//  MKPolylineZoom.swift
//  TrackingLocation
//
//  Created by admin on 5/9/17.
//  Copyright © 2017 Si Nguyen. All rights reserved.
//

import UIKit
import MapKit

class MKPolylineZoom: MKPolyline {
    // fix bug zoom map
    // http://stackoverflow.com/questions/40087736/ios-10-mapkit-previous-layer-zoom-issue
    override var boundingMapRect: MKMapRect {
        return MKMapRectWorld
    }
}
