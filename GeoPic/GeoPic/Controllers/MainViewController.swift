//
//  MainViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/24/21.
//

import UIKit
import MapKit
import Firebase

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var cameraButton: UIButton!
    @IBOutlet private var settingsButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up map
        mapView.delegate = self
        mapView.showsUserLocation = true
        // Remove apple maps logo
        mapView.subviews[1].isHidden = true
        // Remove "legal" button
        mapView.subviews[2].isHidden = true
        // Request location access
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        // TODO: Handle case where user does not accept location services
        
        // Set up camera button
        cameraButton.imageView?.contentMode = .scaleAspectFit
        cameraButton.layer.masksToBounds = true
        cameraButton.layer.cornerRadius = cameraButton.frame.width/2
        
        // Set up settings button
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.layer.masksToBounds = true
        settingsButton.layer.cornerRadius = settingsButton.frame.width/2
        
        loadPins()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // hide navigation bar
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // unhide navigation bar
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func loadPins(){
        let db = Firestore.firestore()
        db.collection("photos").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let url = URL(string: document.data()["photo_url"] as! String)
                    let imageData = try? Data(contentsOf: url!)
                    let image = UIImage(data: imageData!)
                    
                    let point = document.data()["location"] as! GeoPoint
                    let coord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                    
                    let score = document.data()["score"] as! UInt
                    
                    let userID = document.data()["user"] as! String
                    
                    let pinID = document.documentID
                    
                    let timestamp = document.data()["date"] as! Timestamp
                    let date = timestamp.dateValue()

                    let pin = Pin(id: pinID, image: image, coordinate: coord, score: score, userID: userID, date: date)
                    
                    self.mapView.addAnnotation(pin)
                }
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Pass pin to segue
        let pin = view.annotation as! Pin
        performSegue(withIdentifier: K.Segues.mainToPicture, sender: pin)
    }
    
    @IBAction func settingsPressed(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.mainToSettings, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.Segues.mainToPicture {
            // Pass pin to the PictureVC
            guard let pin = sender as? Pin else { return }
            if let destinationVC = segue.destination as? PictureViewController {
                destinationVC.pin = pin
            }
        }
    }
    
    // Taken from: https://stackoverflow.com/questions/52564004/location-marker-not-displaying-swift-4
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let locValue:CLLocationCoordinate2D = manager.location!.coordinate
            print("location = \(locValue.latitude) \(locValue.longitude)")
            let userLocation = locations.last
            let viewRegion = MKCoordinateRegion(center: (userLocation?.coordinate)!, latitudinalMeters: 600, longitudinalMeters: 600)
            self.mapView.setRegion(viewRegion, animated: true)
        }


}
