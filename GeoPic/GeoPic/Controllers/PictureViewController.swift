//
//  PictureViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/25/21.
//

import UIKit
import Firebase
import Kingfisher
import SwiftMessages

class PictureViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var likeButton: UIButton!
    @IBOutlet private var deleteButton: UIBarButtonItem!
    
    var pin: Pin?
    var userLikedPin = false
    
    var previousVC: MainViewController!
    
    var delegate: PictureViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.hidesWhenStopped = true
        
        likeButton.imageView?.contentMode = .scaleAspectFit
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        
        let db = Firestore.firestore()
        db.settings = settings
        
        // Get pin author name
        let docRef = db.collection("users").document((pin?.userID)!)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.nameLabel.text = document.data()!["name"] as? String
            } else {
                let alert = UIAlertController(title: "Oops...", message: "This picture does not exist anymore", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                alert.addAction(action)
                self.present(alert, animated: true) {
                    self.delegate?.pictureViewDelegate(for: self.pin!, true)
                }
            }
        }
        // hide the trash button on default
        deleteButton.isEnabled = false
        deleteButton.tintColor = .clear
        
        // If current user is creator of pin, show delete button
        if(Auth.auth().currentUser!.uid == (pin?.userID)!){
            deleteButton.isEnabled = true
            deleteButton.tintColor = .none
        }
        
        imageView.kf.indicatorType = .activity
        // Get pin image
        imageView.kf.setImage(with: pin?.url){ result in
            switch result {
            case .success( _):
                print("image successfully loaded")
            case .failure( _):
                print("image failed to load")
                // Haptic feedback when pin is not in range
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                
                // Show error message
                let errorView = MessageView.viewFromNib(layout: .cardView)
                errorView.button?.isHidden = true
                errorView.configureTheme(.error)
                errorView.configureDropShadow()
                errorView.configureContent(title: "Error", body: "Image failed to load!")
                errorView.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
                (errorView.backgroundView as? CornerRoundingView)?.cornerRadius = 10
                SwiftMessages.show(view: errorView)
            }
        }
        // prevent the image from rotating (displaying sideways)
        imageView.transform = CGAffineTransform(rotationAngle: CGFloat(0))
        
        // Get pin date
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        dateLabel.text = formatter.string(from: (pin?.date)!)
        
        // Get pin likes
        loadScore()
        
        // Check if user has already liked the pin
        let curr_user = Auth.auth().currentUser?.uid
        let likesRef = db.collection("photos").document((pin?.id)!).collection("likes")
        let userQuery = likesRef.whereField("uid", isEqualTo: curr_user!)
        userQuery.getDocuments() { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if(snapshot!.documents.count > 0){
                    // User has liked this post already
                    self.userLikedPin = true
                    self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                }
            }
        }

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
  
    @IBAction func back(sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deletePin(sender: UIBarButtonItem){
        activityIndicator("Deleting")
        let db = Firestore.firestore()
        // Delete pin from DB
        db.collection("photos").document((pin?.id)!).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                // Remove pin from map
                self.dismiss(animated: true, completion: {
                    self.previousVC!.deletePin(pin: self.pin!)
                })
                print("Document successfully removed!")
            }
        }
    }
    
    @IBAction func like(sender: UIButton){
        let db = Firestore.firestore()
        let curr_user = (Auth.auth().currentUser?.uid)!
        let pinRef = db.collection("photos").document((pin?.id)!)
        let likesRef = pinRef.collection("likes")
        
        if(userLikedPin){
            // Undo like
            self.userLikedPin = false
            
            // Change button image
            self.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            
            // Decrement pin's score
            pinRef.updateData(["score": FieldValue.increment(Int64(-1))])
            self.pin?.decrementScore()
            self.loadScore()
            
            // Remove uid from likes collection
            let userQuery = likesRef.whereField("uid", isEqualTo: curr_user)
            userQuery.getDocuments() { (snapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    snapshot!.documents.forEach { doc in
                        doc.reference.delete()
                    }
                    print("Like removed")
                }
            }
        } else {
            // Add like
            self.userLikedPin = true
            
            // Change button image
            self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            
            // Increment pin's score
            pinRef.updateData(["score": FieldValue.increment(Int64(1))])
            self.pin?.incrementScore()
            self.loadScore()
            
            // Add uid to likes collection to track who liked each pin
            likesRef.addDocument(data: [
                "uid": curr_user
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Like added")
                }
            }
        }
    }
    
    func loadScore() {
        let score = String((pin?.score)!)
        likeButton.setTitle("(\(score))", for: .normal)
    }
}
