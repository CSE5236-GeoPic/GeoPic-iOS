//
//  PictureViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/25/21.
//

import UIKit
import Firebase

class PictureViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var dateLabel: UILabel!
    @IBOutlet private var scoreLabel: UILabel!
    @IBOutlet private var backButton: UIButton!
    @IBOutlet private var deleteButton: UIButton!
    
    var pin: Pin?
    var previousVC: MainViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document((pin?.userID)!)
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.nameLabel.text = document.data()!["name"] as? String
            } else {
                print("Error retrieving name")
            }
        }
        
        // If current user is creator of pin, show delete button
        if(Auth.auth().currentUser!.uid == (pin?.userID)!){
            deleteButton.isHidden = false
        }
        
        imageView.image = pin?.image
        scoreLabel.text = String((pin?.score)!)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        dateLabel.text = formatter.string(from: (pin?.date)!)

    }
    
    @IBAction func back(sender: UIButton){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deletePin(sender: UIButton){
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

}
