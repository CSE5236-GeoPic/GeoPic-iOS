//
//  ViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/17/21.
//

import UIKit
import IQKeyboardManagerSwift

class LoginViewController: UIViewController {

    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var createAccBtn: UIButton!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // set up corner radius for the two buttons to make them look nicer
        loginBtn.layer.cornerRadius = 10
        createAccBtn.layer.cornerRadius = 10
    }
    
    @IBAction func loginPressed(_ sender: UIButton) {
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.authToCreateAcc, sender: nil)
    }
}

