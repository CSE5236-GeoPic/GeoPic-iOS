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

class MainViewController: UIViewController, CLLocationManagerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var cameraButton: UIButton!
    @IBOutlet private var settingsButton: UIButton!
    @IBOutlet private var locationButton: UIButton!
    
    @IBOutlet var welcomeMessageView: UIView!
    @IBOutlet var welcomeMessageLabel: UILabel!
    
    private let storage = Storage.storage().reference()
    var locationManager = CLLocationManager()
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeMessageView.isHidden = true
        
        // display welcome message
        // retrieve current user's name
        if let userDocumentId = Auth.auth().currentUser?.uid {
            print(userDocumentId)
            let docRef = db.collection("users").document(userDocumentId)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let currentName = document.data()!["name"] as! String
                    
                    // finished getting the current user's name
                    self.welcomeMessageLabel.text = "Welcome \(currentName)!"
                    // set up view
                    self.welcomeMessageView.layer.cornerRadius = 20
                    self.welcomeMessageView.isHidden = false
                    // execute animation
                    self.welcomeMessageView.fadeOut(seconds: 1.0, delay: 2.0)
                } else {
                    // do nothing in UI
                    print("Document does not exist")
                }
            }
        }
        
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

                    let circle = MKCircle(center: coord, radius: K.pinCircleRadius)
                    
                    let pin = Pin(id: pinID, url: url, coordinate: coord, score: score, userID: userID, date: date, circle: circle)
                    
                    self.mapView.addAnnotation(pin)
                    
                    self.mapView.addOverlay(pin.circle!)
                }
            }
        }
        
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
                destinationVC.delegate = self
            }
        }
    }
    
    // Delete pin, called from PictureViewController
    func deletePin(pin: Pin){
        self.mapView.removeAnnotation(pin)
        self.mapView.removeOverlay(pin.circle!)
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

extension MainViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let uncompressedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        guard let image = uncompressedImage.resizeWithPercent(percentage: 0.8) else {
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        //creates uuid for each photo
        let uuid = UUID().uuidString
        
        self.view.isUserInteractionEnabled = false
        //show activity indicator and stop allowing user inputs when uploading photo
        activityIndicator("Uploading")
        print("Start Spinning")
        let uploadPhoto = storage.child("images/\(uuid).jpg").putData(imageData, metadata: nil, completion: {_, error in
            guard error == nil else {
                print("Failed to Upload")
                return
            }
            self.storage.child("images/\(uuid).jpg").downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    return
                }
                let urlString = url.absoluteString
                print("Download URL: \(urlString)")
                self.db.collection("photos").document(uuid).setData([
                    "date" : FieldValue.serverTimestamp(),
                    "location" : GeoPoint(latitude: self.locationManager.location!.coordinate.latitude, longitude: self.locationManager.location!.coordinate.longitude),
                    "photo_url" : urlString,
                    "score" : 0,
                    "user" : Auth.auth().currentUser?.uid as Any
                ])
                
                // done uploading so reload the map
                self.loadPins()
            })
        })
        //stop spinning and give back control upon successful upload, or failure
        uploadPhoto.observe(.success) {snapshot in
            self.centerMapOnUserLocation()
            self.effectView.removeFromSuperview()
            print("Stop Spinning")
            self.view.isUserInteractionEnabled = true
        }
        uploadPhoto.observe(.failure) {snapshot in
            self.centerMapOnUserLocation()
            self.effectView.removeFromSuperview()
            print("Stop Spinning")
            print("Error Uploading")
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension MainViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let userView = mapView.view(for: mapView.userLocation)
        userView?.isUserInteractionEnabled = false
        userView?.isEnabled = false
        userView?.canShowCallout = false
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = view.annotation as? Pin else { return }
        let userLocation = self.locationManager.location!
        let pinLocation = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
#if DEBUG
        let distance = Double(0)
#else
        let distance = userLocation.distance(from: pinLocation)
#endif
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
        circleRenderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
        circleRenderer.strokeColor = .systemBlue
        circleRenderer.lineWidth = 1
        return circleRenderer
    }
}

extension MainViewController: PictureViewDelegate {
    
    func pictureViewDelegate(for pin: Pin, _ isInvalidPin: Bool) {
        // delete the passed in pin from the map and delete the picture document from the db
        
        // delete picture from db
        db.collection("photos").document(pin.id!).delete { (error) in
            if error != nil {
                let alert = UIAlertController(title: "There was a problem deleting the picture", message: "Please try again later", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            } else {
                // delete the pin from the map
                self.deletePin(pin: pin)
            }
        }
    }
}

// Taken from https://stackoverflow.com/a/43256233
extension UIImage {
    func resizeWithPercent(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    func resizeWithWidth(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}

// MARK: - Welcome message animation section
fileprivate extension UIView {
    
    /**
     Animate the UIView to fade out to desired alpha level.
     - Parameter alpha: target alpha level
     - Parameter duration: duration in seconds that the animation will run for
     - Parameter delay: duration in seconds that the animation will be executed after
     */
    private func fadeTo(_ alpha: CGFloat, duration: TimeInterval, delay: TimeInterval) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, delay: delay, options: .curveEaseOut, animations: {
                self.alpha = alpha
            }, completion: nil)
        }
    }
    
    /**
     Fade out this UIView during the passed amount of seconds.
     - Parameter seconds: duration in seconds that the animation will run for
     - Parameter delay: duration in seconds that the animation will be executed after
     */
    func fadeOut(seconds duration: TimeInterval, delay: TimeInterval) {
        self.alpha = 1.0
        fadeTo(0.0, duration: duration, delay: delay)
    }
}
