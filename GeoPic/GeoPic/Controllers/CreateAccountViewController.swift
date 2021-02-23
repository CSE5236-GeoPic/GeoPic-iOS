//
//  CreateAccountViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/22/21.
//

import UIKit

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var createAccBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.isModalInPresentation = true
        // corner radius for create account button
        createAccBtn.layer.cornerRadius = 10
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func createAccPressed(_ sender: UIButton) {
        // FIXME: temporary alert view until Firebase is connected
        let alert = UIAlertController(title: "WIP", message: "Not yet implemented\nThis will create new user in Firebase and close this view", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { handler in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
