//
//  CreateAccountViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/22/21.
//

import UIKit
import Firebase
import KeychainSwift

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var createAccBtn: UIButton!
    
    let defaults = UserDefaults.standard
    
    var delegate: AuthenticationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.isModalInPresentation = true
        // corner radius for create account button
        createAccBtn.layer.cornerRadius = 10
        // textfields setup
        emailTextfield.delegate = self
        nameTextfield.delegate = self
        passwordTextfield.delegate = self
        emailTextfield.tag = 0
        nameTextfield.tag = 1
        passwordTextfield.tag = 2
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        firebaseCreateAccount(email: emailTextfield.text!, password: passwordTextfield.text!)
    }
    
    // MARK: - Private helper methods
    /**
     Attempts to create a new user in Firebase.
     If successful, displays an alert dialog notifying the user of the success and dismisses the current modal.
     If unsuccessful, displays an alert dialog notifying the user of the failure.
     Upon successful user creation, `users` collection on Firestore will have the user with document ID of `Auth.auth().currentUser.uid` value with the user's full name.
     - Parameter email: email of new user
     - Parameter password: password of new user
     */
    private func firebaseCreateAccount(email: String, password: String) {// check if email field has a valid email
        if !email.isValidEmail() {
            let alert = UIAlertController(title: "Invalid email!", message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if error != nil {
                // something went wrong while creating an account
                let alert = UIAlertController(title: "Something went wrong", message: "There was a problem while creating your account. Please try again later", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
            } else {
                let documentId = authResult!.user.uid
                // Add a new document in collection "users"
                Firestore.firestore().collection("users").document(documentId).setData([
                    "name": self.nameTextfield.text!
                ]) { err in
                    if err != nil {
                        let alert = UIAlertController(title: "Something went wrong", message: "There was a problem while creating your account. Please try again later", preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alert.addAction(action)
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        // account created
                        // update keychain information for biometrics
                        let keychain = KeychainSwift()
                        keychain.set(self.emailTextfield.text!, forKey: "email")
                        keychain.set(self.passwordTextfield.text!, forKey: "password")
                        // display success message
                        let alert = UIAlertController(title: "Account Created!", message: "Your account was successfully created!", preferredStyle: .alert)
                        let action = UIAlertAction(title: "OK", style: .default) { handler in
                            
                            self.dismiss(animated: true) {
                                self.delegate?.authenticationDelegate(true, email: self.emailTextfield.text!, name: self.nameTextfield.text!)
                            }
                        }
                        alert.addAction(action)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
            }
        }
    }
}

// MARK: - Email validation function for String
fileprivate extension String {
    func isValidEmail() -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}

// MARK: - Textfield delegate methods
extension CreateAccountViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            nameTextfield.becomeFirstResponder()
            return false
        case 1:
            passwordTextfield.becomeFirstResponder()
            return false
        case 2:
            firebaseCreateAccount(email: emailTextfield.text!, password: passwordTextfield.text!)
        default:
            print("Should never get here")
        }
        return true
    }
}
