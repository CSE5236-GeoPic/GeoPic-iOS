//
//  MainViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/24/21.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseStorage

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var cameraButton: UIButton!
    @IBOutlet private var settingsButton: UIButton!
    
    private let storage = Storage.storage().reference()
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
        activityIndicator.hidesWhenStopped = true
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
    
    //Activity indicator with text
    //From https://stackoverflow.com/questions/28785715/how-to-display-an-activity-indicator-with-text-on-ios-8-with-swift
    
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    func activityIndicator(_ title: String) {
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 160, height: 46))
        strLabel.text = title
        strLabel.font = .systemFont(ofSize: 14, weight: .medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        effectView.frame = CGRect(x: view.frame.midX - strLabel.frame.width/2, y: view.frame.midY - strLabel.frame.height/2 , width: 160, height: 46)
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        activityIndicator.startAnimating()
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        view.addSubview(effectView)
    }
    
    // Opens native iOS camera when pressing camera button
    @IBAction func openCamera(_ sender: Any) {
        // Do something else for a simulator because it will crash
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let alert = UIAlertController(title: "Unable to open camera", message: "This device does not have a camera", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        guard let imageData = image.pngData() else {
            return
        }
        //creates uuid for each photo
        let uuid = UUID().uuidString
        let db = Firestore.firestore()
        self.view.isUserInteractionEnabled = false
        //show activity indicator and stop allowing user inputs when uploading photo
        activityIndicator("Uploading")
        print("Start Spinning")
        let uploadPhoto = storage.child("images/\(uuid).png").putData(imageData, metadata: nil, completion: {_, error in
            guard error == nil else {
                print("Failed to Upload")
                return
            }
            self.storage.child("images/\(uuid).png").downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    return
                }
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                db.collection("photos").document(uuid).setData([
                    "date" : FieldValue.serverTimestamp(),
                    "location" : GeoPoint(latitude: self.locationManager.location!.coordinate.latitude, longitude: self.locationManager.location!.coordinate.longitude),
                    "photo_url" : urlString,
                    "score" : 0,
                    "user" : Auth.auth().currentUser?.uid as Any
                ])
            })
        })
        //stop spinning and give back control upon successful upload, or failure
        uploadPhoto.observe(.success) {snapshot in
            self.effectView.removeFromSuperview()
            print("Stop Spinning")
            self.view.isUserInteractionEnabled = true
        }
        uploadPhoto.observe(.failure) {snapshot in
            self.effectView.removeFromSuperview()
            print("Stop Spinning")
            print("Error Uploading")
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func loadPins(){
        let db = Firestore.firestore()
        db.collection("photos").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let url = URL(string: document.data()["photo_url"] as! String)
                    
                    let point = document.data()["location"] as! GeoPoint
                    let coord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                    
                    let score = document.data()["score"] as! UInt
                    
                    let userID = document.data()["user"] as! String
                    
                    let pinID = document.documentID
                    
                    let timestamp = document.data()["date"] as! Timestamp
                    let date = timestamp.dateValue()

                    let pin = Pin(id: pinID, url: url, coordinate: coord, score: score, userID: userID, date: date)
                    
                    self.mapView.addAnnotation(pin)
                }
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = view.annotation as? Pin else { return }
        let userLocation = self.locationManager.location!
        let pinLocation = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        let distance = userLocation.distance(from: pinLocation)
        print(distance)
        // Pass pin to segue
        self.mapView.deselectAnnotation(pin, animated: false)
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
                destinationVC.previousVC = self
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
    
    // Delete pin, called from PictureViewController
    func deletePin(pin: Pin){
        self.mapView.removeAnnotation(pin)
    }
    
    // Refenced https://stackoverflow.com/a/38383598
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else {
            return nil
        }

        let annotationIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        } else {
            annotationView!.annotation = annotation
        }
        
        let image = UIImage(systemName: "pin.fill")
        annotationView!.image = image

        return annotationView
    }
}
