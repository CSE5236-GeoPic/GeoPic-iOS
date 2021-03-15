//
//  SettingsChangeViewController.swift
//  GeoPic
//
//  Created by John Choi on 3/15/21.
//

import UIKit
import Firebase

enum ChangeType {
    case name
    case password
}

/**
 Disclaimer: Before making a segue to this view, make sure `changeType` and `pageTitle` are given a value.
 
 Example:
 In `prepare(segue:sender:)`, do
 ```
 let vc = segue.destination as! SettingsChangeViewController
 vc.changeType = .name
 vc.pageTitle = "Foo Bar"
 ```
 */
class SettingsChangeViewController: UIViewController {
    
    @IBOutlet var currentNameElements: UIStackView!
    @IBOutlet var newNameElements: UIStackView!
    @IBOutlet var currentPasswordElements: UIStackView!
    @IBOutlet var newPasswordElements: UIStackView!
    @IBOutlet var confirmPasswordElements: UIStackView!
    
    @IBOutlet var currentNameLabel: UILabel!
    @IBOutlet var newNameField: UITextField!
    @IBOutlet var currentPasswordField: UITextField!
    @IBOutlet var newPasswordField: UITextField!
    @IBOutlet var confirmPasswordField: UITextField!
    
    var changeType: ChangeType!
    var pageTitle: String!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setup()
    }
    
    /**
     Retrives the current user's full name and displays it.
     Only present the required text fields based on the operation being performed.
     For example, for a name change request, only the new name field will display.
     */
    private func setup() {
        // retrieve current user's name
        if let userDocumentId = Auth.auth().currentUser?.uid {
            print(userDocumentId)
            let docRef = db.collection("users").document(userDocumentId)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let currentName = document.data()!["name"] as! String
                    self.currentNameLabel.text = currentName
                } else {
                    print("Document does not exist")
                }
            }
        }
        self.title = pageTitle
        if changeType == .name {
            currentPasswordElements.isHidden = true
            newPasswordElements.isHidden = true
            confirmPasswordElements.isHidden = true
        } else {
            newNameElements.isHidden = true
        }
    }
    
    @IBAction func changePressed(_ sender: UIBarButtonItem) {
        if changeType == .name {
            // make sure the name is valid
            if let newName = newNameField.text, newName.count > 0 {
                updateName()
            } else {
                let alert = UIAlertController(title: "Invalid name!", message: "Name is not valid", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
            }
        } else {
            // make sure current password is correct
            // NOTE: Current password check not implemented
//            if !checkCurrentPassword(password: currentPasswordField.text!) {
//                let alert = UIAlertController(title: "Incorrect password!", message: "", preferredStyle: .alert)
//                let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
//                alert.addAction(action)
//                present(alert, animated: true, completion: nil)
//                return
//            }
            // make sure new password matches second password
            if newPasswordField.text! != confirmPasswordField.text! {
                let alert = UIAlertController(title: "Passwords must match!", message: "", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
                return
            }
            // try to change password using Firebase Auth
            Auth.auth().currentUser?.updatePassword(to: newPasswordField.text!, completion: { (error) in
                if error != nil {
                    // something bad happened here
                    let alert = UIAlertController(title: "Failed to change password", message: "Please try again later", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    // password changed successfully
                    let alert = UIAlertController(title: "Password changed!", message: "", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .cancel) { handler in
                        self.navigationController?.popViewController(animated: true)
                    }
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
    }
    
    /**
     Updates the current user's name on Firebase.
     */
    private func updateName() {
        guard let userDocumentId = Auth.auth().currentUser?.uid else {
            let alert = UIAlertController(title: "Something went wrong", message: "There was a problem making changes. Please try again later.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            return
        }
        db.collection("users").document(userDocumentId).setData([
            "name": newNameField.text!
        ]) { err in
            if err != nil {
                let alert = UIAlertController(title: "Something went wrong", message: "There was a problem making changes. Please try again later.", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Success", message: "Name successfully changed to \(self.newNameField.text!)", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .cancel) { handler in
                    self.navigationController?.popViewController(animated: true)
                }
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func checkCurrentPassword(password: String) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var loginSuccessful = false
        
        let user = Auth.auth().currentUser
        let credential = EmailAuthProvider.credential(withEmail: (Auth.auth().currentUser?.email)!, password: newPasswordField.text!)
        
        // Prompt the user to re-provide their sign-in credentials
        user?.reauthenticate(with: credential) { result, error in
            if error != nil {
                // An error happened.
                
            } else {
                // User re-authenticated.
                loginSuccessful = true
            }
            semaphore.signal()
        }
        
            print("here")
        semaphore.wait()
        print(Auth.auth().currentUser!.uid)
        return loginSuccessful
        
        
        
    }
}
