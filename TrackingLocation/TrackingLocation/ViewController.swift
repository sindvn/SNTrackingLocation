import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var locations: [CLLocation] = []
    var backgroundLocations: [CLLocation] = []

    var logger = LocationLogger()
    var currentPolyline: MKPolyline?
    var currentBackgroundPolyline: MKPolyline?
    
    var regionLocation : CLLocation?
    var visitLocation : CLLocation?
    var trackLocation : CLLocation?

    var circles: [MKCircle] = []
    
    override func viewDidLoad() {
        mapView.delegate = self
        super.viewDidLoad()
        
        BackgroundDebug().print()
    }
    
    private func stringFromDate(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    @IBAction func start(_ sender: Any) {
        startTracking()
    }
    
    var appDelagete = {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    @IBAction func stop(_ sender: Any) {
        self.stopTracking()
    }
    
    @IBAction func clear(_ sender: Any) {
        if let polyline = currentPolyline {
            mapView.remove(polyline)
        }
        if let polyline = currentBackgroundPolyline {
            mapView.remove(polyline)
        }
    }
    
    
    @IBAction func readLog(_ sender: Any) {
        if let locations = logger.readLocation() {
            drawLocation(locations: locations)
            centerCamera(to: locations.last!)
        }
    }
    
    @IBAction func clearLog(_ sender: Any) {
        logger.removeLogFile()
    }
    
    func startBackgroundTracking() {
        appDelagete().backgroundLocationManager.startBackground() { [unowned self] result in
            if case let .Success(location) = result {
                self.updateBackgroundLocation(location: location)
            }
        }
    }
    
    private func startTracking() {
        drawRegions()
        
        // TODO: handle location start in background if need
        // can call appDelagete().backgroundLocationManager.startBackground()
        // replace startBackground() in AppDelegate by this function in ViewController
        
        self.startBackgroundTracking()
        /*
        appDelagete().backgroundLocationManager.start() { [unowned self] result in
            if case let .Success(location) = result {
                self.updateBackgroundLocation(location: location)
            }
        }*/
        
        appDelagete().locationManager.start {[unowned self] result in
            if case let .Success(location) = result {
                self.updateLocation(location: location)
            }
        }
    }
    
    private func stopTracking() {
        appDelagete().locationManager.stop()
        appDelagete().backgroundLocationManager.stop()
    }
    
    var isCenter = false
    
    private func updateBackgroundLocation(location: CLLocation) {
        
        // restart location manager when it may be stop tracking
        if let lastLocation = trackLocation, lastLocation.horizontalAccuracy < BackgroundLocationManager.RegionConfig.regionRadius, location.distance(from: lastLocation) > BackgroundLocationManager.RegionConfig.regionRadius {
            
            trackLocation = nil
            regionLocation = nil
            self.stopTracking()
            self.startTracking()
        }
        
        regionLocation = location
        
        backgroundLocations.append(location)
        
        if let polyline = currentBackgroundPolyline {
            mapView.remove(polyline)
        }
        
        currentBackgroundPolyline = ViewController.polyline(locations: backgroundLocations, title: "regions")
        mapView.add(currentBackgroundPolyline!)
        
        logger.writeLocationToFile(location: location)
        
    }
    
    private func updateLocation(location: CLLocation) {
        
        if let region = regionLocation, location.horizontalAccuracy < 50 {
            
            // compare region with location tracking if distance > distanceAroundRegion -> try to restart region monitor
            // fix bug region not update, location not update
            if region.distance(from: location) > BackgroundLocationManager.RegionConfig.regionRadius {
                
                regionLocation = nil
                self.stopTracking()
                self.startTracking()
                
                if let _ = visitLocation {
                    visitLocation = nil
                    self.showNotification("left \(location.coordinate.latitude) :: \(location.coordinate.longitude) leftDate \(self.stringFromDate(date: location.timestamp)) ")
                }
            }
            else if visitLocation == nil {
                
                let time = location.timestamp.timeIntervalSince1970 - region.timestamp.timeIntervalSince1970
                
                if time > (60*5) {
                    
                    // user can move 10-15m in region after that he stop
                    // long-lat will be location
                    // arrival time will be time in region
                    
                    visitLocation = location
                    
                    self.showNotification("arrival \(location.coordinate.latitude) :: \(location.coordinate.longitude) arrivalDate \(self.stringFromDate(date: region.timestamp))")
                    
                    let annotation = MapAnnotation.init(title: "date \(region.timestamp)", coordinate: location.coordinate)
                    mapView.addAnnotation(annotation)
                }
            }
        }
        
        trackLocation = location
        
        locations.append(location)
        
        if let polyline = currentPolyline {
            mapView.remove(polyline)
        }

        drawLocation(locations: locations)
        centerCamera(to: location)
        
    }
    
    private func centerCamera(to location: CLLocation) {
        if !isCenter {
            let camera = mapView.camera
            camera.centerCoordinate = location.coordinate
            
            mapView.camera = camera
            let viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
            
            mapView.setRegion(viewRegion, animated: true)
            isCenter = true
        }
    }
    
    func drawLocation(locations: [CLLocation]) {
        currentPolyline = ViewController.polyline(locations: locations, title: "location")
        mapView.add(currentPolyline!)
    }
    
    
    static func polyline(locations: [CLLocation], title:String) -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                 longitude: location.coordinate.longitude))
        }
        
        let polyline = MKPolyline(coordinates: &coords, count: locations.count)
        polyline.title = title
        
        return polyline
    }
    
    func drawRegions() {
        appDelagete().backgroundLocationManager.addedRegionsListener = { result in
            
            if case let .Success(locations) = result {
                
                self.circles.forEach({ circle in
                    self.mapView.remove(circle)
                })
                
                locations.forEach({ location in
                    let circle = MKCircle(center: location.coordinate, radius: BackgroundLocationManager.RegionConfig.regionRadius)
                    circle.title = "regionPlanned"
                    self.mapView.add(circle)
                    self.circles.append(circle)
                })
                
                
            }
        }

    }

    func showNotification(_ message : String)  {
        let localNotification = UILocalNotification()
        localNotification.alertBody =  message
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.fireDate = Date()
        UIApplication.shared.scheduleLocalNotification(localNotification)
        
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            let isRegion = circle.title ?? "" == "regionPlanned"
            renderer.fillColor = isRegion ? UIColor.blue.withAlphaComponent(0.2) : UIColor.red.withAlphaComponent(0.2)
            return renderer
        }
        
        
        let isRegion = overlay.title ?? "" == "regions"
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = isRegion ? UIColor.red.withAlphaComponent(0.8) : UIColor.blue.withAlphaComponent(0.8)
        renderer.lineWidth = isRegion ? 8.0 : 2.0
        
        return renderer
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else {
            return nil
        }
        
        let reuseIdentifier = "annotationIdentifier"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true
        }
        else {
            annotationView?.annotation = annotation
        }
        
        if let mapAnnotation = annotation as? MapAnnotation {
            annotationView?.image = UIImage.init(named: "pin_icon")
        }
        
        return annotationView
    }
}
