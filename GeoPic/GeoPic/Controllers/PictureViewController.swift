//
//  PictureViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/25/21.
//

import UIKit
import Firebase
import Kingfisher

class PictureViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var likeButton: UIButton!
    
    var pin: Pin?
    var userLikedPin = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let db = Firestore.firestore()
        
        // Get pin author name
        let docRef = db.collection("users").document((pin?.userID)!)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.nameLabel.text = document.data()!["name"] as? String
            } else {
                print("Error retrieving name")
            }
        }
        
        // Get pin image
        imageView.kf.setImage(with: pin?.url)
        
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
    @IBAction func back(sender: UIBarButtonItem){
        self.dismiss(animated: true, completion: nil)
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
