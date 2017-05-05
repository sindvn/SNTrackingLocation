import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var circles: [MKCircle] = []
    
    var currentPolyline: MKPolyline?
    var currentBackgroundPolyline: MKPolyline?
    
    var locations: [Location] = []
    var backgroundLocations: [Location] = []
    
    var locationVisit : Location?
    var isFilter = false
    
    var locationFilter : LocationFilterProtocol!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.mapView.userTrackingMode = .follow
        TrackingService.shared.delegate = self
        locationFilter = LocationFilter()
    }
    
    @IBAction func tapFilter(_ sender: Any) {
        isFilter = true
        self.clearDataMapView()
        let (proccessedLocations, _) = locationFilter.filter(locations)
        self.drawBackgroundPolyline(locations: proccessedLocations)
        self.drawAnnotations(locations: locations, isFilter: false)
        self.drawAnnotations(locations: proccessedLocations, isFilter: true)
    }
    
    @IBAction func tapRaw(_ sender: Any) {
        isFilter = false
        self.clearDataMapView()
        self.drawCurrentPolyline(locations: locations)
        self.drawBackgroundPolyline(locations: backgroundLocations)
        self.drawAnnotations(locations: locations, isFilter: false)
    }
    
    @IBAction func tapClear(_ sender: Any) {
        self.clearDataMapView()
    }
    
    @IBAction func tapStart(_ sender: Any) {
        TrackingService.shared.start()
    }
    
    @IBAction func tapStop(_ sender: Any) {
        TrackingService.shared.stop()
    }
    
    private func clearDataMapView() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    func polyline(coords: [CLLocationCoordinate2D], title:String) -> MKPolyline {
        
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        polyline.title = title
        
        return polyline
    }
    
    func drawCurrentPolyline(locations:[Location]) {
        if let polyline = currentPolyline {
            mapView.remove(polyline)
        }
        var coords = [CLLocationCoordinate2D]()
        locations.forEach { loc in
            coords.append(CLLocationCoordinate2D(latitude:loc.latitude, longitude:loc.longitude))
        }
        currentPolyline = self.polyline(coords: coords, title: "location")
        mapView.add(currentPolyline!)
    }
    
    func drawBackgroundPolyline(locations:[Location]) {
        if let polyline = currentBackgroundPolyline {
            mapView.remove(polyline)
        }
        var coords = [CLLocationCoordinate2D]()
        locations.forEach { loc in
            coords.append(CLLocationCoordinate2D(latitude:loc.latitude, longitude:loc.longitude))
        }
        currentBackgroundPolyline = self.polyline(coords: coords, title: "regions")
        mapView.add(currentBackgroundPolyline!)
    }
    
    func drawAnnotations(locations:[Location],isFilter:Bool) {
        locations.forEach { loc in
            if let arrivalDate = loc.arrivalTime {
                let annotation = MapAnnotation.init(title: "date \(arrivalDate)", coordinate: CLLocationCoordinate2D(latitude:loc.latitude, longitude:loc.longitude), isAnnotationPickMap: isFilter)
                mapView.addAnnotation(annotation)
            }
            
        }
    }
}

extension ViewController : TrackingServiceDelegate {
    
    func didUpdateTrackingLocation(_ location: CLLocation) {
        let locationData = Location(uuid: NSUUID().uuidString, longitude: location.coordinate.longitude, latitude: location.coordinate.latitude, horizontalAccuracy: location.horizontalAccuracy, createdAt: location.timestamp)
        locations.append(locationData)
        
        if isFilter == false {
            self.drawCurrentPolyline(locations: locations)
        }
    }
    
    func didUpdateBackgroundLocation(_ location: CLLocation) {
        let locationData = Location(uuid: NSUUID().uuidString, longitude: location.coordinate.longitude, latitude: location.coordinate.latitude, horizontalAccuracy: location.horizontalAccuracy, createdAt: location.timestamp)
        backgroundLocations.append(locationData)
        
        if isFilter == false {
            self.circles.forEach({ circle in
                self.mapView.remove(circle)
            })
            let circle = MKCircle(center: location.coordinate, radius: BackgroundLocationManager.RegionConfig.regionRadius)
            circle.title = "regionPlanned"
            self.mapView.add(circle)
            self.circles.append(circle)
            
            self.drawBackgroundPolyline(locations: backgroundLocations)
        }
    }
    
    func didDepartLocation(_ location: CLLocation, arrivalDate: Date, departureDate: Date) {
        if let visit = locationVisit {
            visit.departureTime = departureDate
        }
    }
    
    func didArrivalLocation(_ location: CLLocation, arrivalDate : Date) {
        locationVisit = Location.init(uuid: NSUUID().uuidString, longitude: location.coordinate.longitude, latitude: location.coordinate.latitude, horizontalAccuracy: location.horizontalAccuracy, createdAt: location.timestamp, arrivalTime: arrivalDate, departureTime: nil, transport: nil, medias: nil)
        locations.append(locationVisit!)
        
        if isFilter == false {
            let annotation = MapAnnotation.init(title: "date \(arrivalDate)", coordinate: location.coordinate, isAnnotationPickMap: false)
            mapView.addAnnotation(annotation)
        }
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
        
        if let annotation = annotation as? MapAnnotation {
            annotationView?.image = annotation.isPickOnMap ? UIImage.init(named: "icon_annotation_green") : UIImage.init(named: "icon_annotation_blue")
        }
        
        return annotationView
    }
}
