import CoreLocation

public enum Result<T> {
    case Success(T)
    case Error(Error)
}

public typealias LocationListener = (Result<CLLocation>) -> ()

protocol TrackingLocationManagerDelegate: class {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
}

final public class TrackingLocationManager: NSObject {
    
    fileprivate lazy var significantLocationManager: CLLocationManager = {
        var locationManager: CLLocationManager = CLLocationManager()
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestAlwaysAuthorization()
        return locationManager
    }()
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        return locationManager
    }()
    
    weak var delegate: TrackingLocationManagerDelegate?
    
    fileprivate var listener: LocationListener?
    
    func setAlwaysUpdateLocation() {
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func setPeriodicallyUpdateLocation(outdoor: Bool = false) {
        locationManager.distanceFilter = 30
        // The accuracy of outdoor locations is in range 5...32
        locationManager.desiredAccuracy = outdoor ? 20.0 : kCLLocationAccuracyHundredMeters
    }
    
    func setUpdateLocationEachHundredKilometers() {
        locationManager.distanceFilter = 100000 //100km
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    func startSignificantLocationChanges() {
        significantLocationManager.delegate = self
        significantLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    func requestLocation(listener: @escaping LocationListener) {
        self.listener = listener
        locationManager.delegate = self
        
        if significantLocationManager.delegate == nil {
            startSignificantLocationChanges()
        }
        locationManager.requestLocation()
    }
    
    public func start(listener: @escaping LocationListener) {
        self.listener = listener
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    public func stop() {
        locationManager.stopUpdatingLocation()
    }
}

extension TrackingLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.max(by: { (location1, location2) -> Bool in
            return location1.timestamp.timeIntervalSince1970 < location2.timestamp.timeIntervalSince1970}) else { return }
        
        if manager == significantLocationManager {
            locationManager.requestLocation()
        } else if (location.horizontalAccuracy < Config.LocationService.maxHorizontalAccuracy
            && Date().timeIntervalSince(location.timestamp) < Config.LocationService.minLocationTimestampFromNow ){
            listener?(Result.Success(location))
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.locationManager(manager, didChangeAuthorization: status)
    }
}
