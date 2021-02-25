//
//  MainViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/24/21.
//

import UIKit
import MapKit

class MainViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet private var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        // TODO: Handle case where user does not accept location services
        
        mapView.showsUserLocation = true

    }
    
    // Taken from: https://stackoverflow.com/questions/52564004/location-marker-not-displaying-swift-4
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let locValue:CLLocationCoordinate2D = manager.location!.coordinate
            print("locations = \(locValue.latitude) \(locValue.longitude)")
            let userLocation = locations.last
            let viewRegion = MKCoordinateRegion(center: (userLocation?.coordinate)!, latitudinalMeters: 600, longitudinalMeters: 600)
            self.mapView.setRegion(viewRegion, animated: true)
        }


}
