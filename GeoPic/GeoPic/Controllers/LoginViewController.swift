//
//  LoginViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/17/21.
//

import UIKit
import KeychainSwift
import LocalAuthentication
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var createAccBtn: UIButton!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var biometricBtn: UIButton!
    
    let keychain = KeychainSwift()
    let localAuthenticationContext = LAContext()
    let defaults = UserDefaults.standard
    // if biometric button is hidden, biometric is not available
    var biometricIsAvailable: Bool {
        return !biometricBtn.isHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set up corner radius for the two buttons to make them look nicer
        loginBtn.layer.cornerRadius = 10
        createAccBtn.layer.cornerRadius = 10
        
        // textfields setup
        emailTextfield.tag = 0
        passwordTextfield.tag = 1
        emailTextfield.delegate = self
        passwordTextfield.delegate = self

        // populate email field with saved email from user defaults if there's one
        if let email = defaults.string(forKey: "email") {
            emailTextfield.text = email
        }
        
        // determine if device has FaceID or TouchID and set appropriate image for the biometrics button
        var biometricsError: NSError?
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &biometricsError) {
            if localAuthenticationContext.biometryType == .touchID {
                print("here")
                biometricBtn.setBackgroundImage(UIImage(systemName: "touchid"), for: .normal)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // hides navigation bar when this view is loaded
        self.navigationController?.isNavigationBarHidden = true
        
        // if email in UserDefaults is empty string, clear the email text field
        if let email = (defaults.value(forKey: "email") as? String), email.isEmpty {
            // if here, account was deleted
            emailTextfield.text = ""
        }
        // clear password field
        passwordTextfield.text = ""
        
        // determine if keychain has username and password and if true, enable biometrics
        biometricBtn.isHidden = true
        if let _ = keychain.get("email"), let _ = keychain.get("password") {
            // if username and password exists in the keychain, biometric is available
            biometricBtn.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // unhides navigatino bar when this view is disappearing
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
        login(with: .emailPassword)
    }
    
    @IBAction func biometricPressed(_ sender: UIButton) {
        login(with: .biometric)
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.authToCreateAcc, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.Segues.authToCreateAcc {
            let vc = segue.destination as! CreateAccountViewController
            vc.delegate = self
        }
    }
    
    // MARK: - Private methods
    /**
     Performs login using either email and password for `LoginMethod.emailPassword` or using biometrics for `LoginMethod.biometric`.
     - Parameter method: the login method to attempt
     */
    private func login(with method: LoginMethod) {
        if method == .emailPassword {
            // login using email and password
            firebaseLogin(email: emailTextfield.text!, password: passwordTextfield.text!, with: method)
        } else {
            // login using biometric
            localAuthenticationContext.localizedFallbackTitle = "Please use other login method"
            
            // check if biometric is available
            var authorizationError: NSError?
            if localAuthenticationContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &authorizationError) {
                print("Biometrics is supported")
                // for both faceID and touchID, try logging in using the email and password stored in keychain
                localAuthenticationContext.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: "GeoPic uses biometrics for signin") { [self] (success, error) in
                    if success {
                        print("Success")
                        // login to firebase using values stored in keychain
                        firebaseLogin(email: keychain.get("email")!, password: keychain.get("password")!, with: method)
                    } else {
                        print("Error \(String(describing: error))")
                    }
                }
            }
        }
    }
    
    /**
     Attempts login to Firebase using the passed in email and password.
     If login is successful, `performSegue(withIdentifier:sender)` is called.
     If login is unsuccessful, alert dialog is displayed to let the user know.
     - Parameter email: user email to use for sign in
     - Parameter password: user password to use for sign in
     - Parameter method: authentication method
     */
    private func firebaseLogin(email: String, password: String, with method: LoginMethod) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            // check for any errors with sign in
            if error != nil {
                // login unsuccessful
                // display error message if login failed
                let alert = UIAlertController(title: "Login Failed!", message: "There was a problem logging in. Please try again.", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .cancel) { handler in
                    strongSelf.emailTextfield.becomeFirstResponder()
                }
                alert.addAction(action)
                strongSelf.present(alert, animated: true)
            } else {
                // login successful
                print("successful firebase")
                // save email to the user defaults
                strongSelf.defaults.setValue(email, forKey: "email")
                if method == .emailPassword {
                    // if user logged in using email and password, ask them if they want biometrics for next time
                    let alert = UIAlertController(title: "Login Successful", message: "Would you like to use biometrics for sign in?", preferredStyle: .alert)
                    let yesAction = UIAlertAction(title: "Yes", style: .default) { (action) in
                        // to enroll in biometrics, save the email and password to the keychain
                        strongSelf.keychain.set(email, forKey: "email")
                        strongSelf.keychain.set(password, forKey: "password")
                        
                        // perform segue to main screen
                        strongSelf.performSegue(withIdentifier: K.Segues.loginToMain, sender: nil)
                    }
                    let noAction = UIAlertAction(title: "No", style: .default) { (action) in
                        // perform segue to main screen
                        strongSelf.performSegue(withIdentifier: K.Segues.loginToMain, sender: nil)
                    }
                    alert.addAction(yesAction)
                    alert.addAction(noAction)
                    strongSelf.present(alert, animated: true)
                } else {
                    // perform segue to main screen
                    strongSelf.performSegue(withIdentifier: K.Segues.loginToMain, sender: nil)
                }
            }
        }
    }
}

// MARK: - Textfield delegate methods
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            passwordTextfield.becomeFirstResponder()
            return false
        case 1:
            login(with: .emailPassword)
        default:
            print("should never get here")
        }
        return true
    }
}

// MARK: - Authentication Delegate method
extension LoginViewController: AuthenticationDelegate {
    func authenticationDelegate(_ userCreated: Bool, email: String, name: String) {
        self.emailTextfield.text = email
        defaults.setValue(email, forKey: "email")
        // if signed in, make segue to main screen
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: K.Segues.loginToMain, sender: nil)
        }
    }
}

// MARK: - Enum that defines login method
fileprivate enum LoginMethod {
    case emailPassword
    case biometric
}
