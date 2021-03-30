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
    
    var pin: Pin?

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
        
        imageView.image = pin?.image
        scoreLabel.text = String((pin?.score)!)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        dateLabel.text = formatter.string(from: (pin?.date)!)

    }
    @IBAction func back(sender: UIBarButtonItem){
        self.dismiss(animated: true, completion: nil)
    }

}
