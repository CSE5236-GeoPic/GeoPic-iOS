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
import SwiftMessages

class MainViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var cameraButton: UIButton!
    @IBOutlet private var settingsButton: UIButton!
    @IBOutlet private var locationButton: UIButton!
    
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
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            fallthrough
        case .authorizedWhenInUse:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        case .denied:
            let alert = UIAlertController(title: "GeoPic needs to use the location data", message: "Please go to Settings -> App Settings -> Enable location services and enable location services", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                self.navigationController?.popViewController(animated: true)
            }
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
                let url = URL(string: UIApplication.openSettingsURLString)!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url) { completion in
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
            alert.addAction(cancelAction)
            alert.addAction(settingsAction)
            self.present(alert, animated: true, completion: nil)
        default:
            print("should not be here")
        }
        
        // Set up camera button
        cameraButton.imageView?.contentMode = .scaleAspectFit
        cameraButton.layer.masksToBounds = true
        cameraButton.layer.cornerRadius = cameraButton.frame.width/2
        
        // Set up settings button
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.layer.masksToBounds = true
        settingsButton.layer.cornerRadius = settingsButton.frame.width/2
        activityIndicator.hidesWhenStopped = true
        
        // Set up location button
        locationButton.imageView?.contentMode = .scaleAspectFit
        locationButton.layer.masksToBounds = true
        locationButton.layer.cornerRadius = locationButton.frame.width/2
        
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
            self.centerMapOnUserLocation()
            self.loadPins()
            self.effectView.removeFromSuperview()
            print("Stop Spinning")
            self.view.isUserInteractionEnabled = true
        }
        uploadPhoto.observe(.failure) {snapshot in
            self.centerMapOnUserLocation()
            self.loadPins()
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
        // Remove any pins currently on map
        let annotations = mapView.annotations.filter({ !($0 is MKUserLocation) })
        mapView.removeAnnotations(annotations)
        
        // Load pins
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
                    
                    let timestamp = document.get("date", serverTimestampBehavior: .estimate) as! Timestamp
                    let date = timestamp.dateValue()

                    let pin = Pin(id: pinID, url: url, coordinate: coord, score: score, userID: userID, date: date)
                    
                    self.mapView.addAnnotation(pin)
                    
                    let circle = MKCircle(center: coord, radius: K.pinCircleRadius)
                    self.mapView.addOverlay(circle)
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
        // Return if user is not in the radius of the pin
        if(distance <= K.pinCircleRadius){
            // Pass pin to segue
            performSegue(withIdentifier: K.Segues.mainToPicture, sender: pin)
        } else {
            // Haptic feedback when pin is not in range
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            // Show error message
            let errorView = MessageView.viewFromNib(layout: .cardView)
            errorView.button?.isHidden = true
            errorView.configureTheme(.error)
            errorView.configureDropShadow()
            errorView.configureContent(title: "Alert", body: "You must be within \(Int(K.pinCircleRadius)) meters of the pin to view it!")
            errorView.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            (errorView.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            SwiftMessages.show(view: errorView)
        }
        self.mapView.deselectAnnotation(pin, animated: false)
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
        
        let image = UIImage(named: "pin")
        annotationView!.image = image
        annotationView!.frame.size = CGSize(width: K.pinSize, height: K.pinSize)

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
        circleRenderer.strokeColor = .blue
        circleRenderer.lineWidth = 1
        return circleRenderer
    }
    
    @IBAction func locationPressed(_ sender: UIButton) {
        centerMapOnUserLocation()
    }
    
    // Moves map and zooms to location
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: K.mapSize, longitudinalMeters: K.mapSize)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}
