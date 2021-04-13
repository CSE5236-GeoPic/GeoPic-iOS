//
//  SettingsViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/28/21.
//

import UIKit
import Firebase
import KeychainSwift

class SettingsViewController: UIViewController {

    @IBOutlet weak var table: UITableView!
    
    // list of settings available
    let settingsItems: [String] = ["Change Name", "Change Password", "Delete Account", "Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // table setup
        table.dataSource = self
        table.delegate = self
        // register table cell to display on table
        table.register(SettingsTableViewCell.nib, forCellReuseIdentifier: SettingsTableViewCell.identifier)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.Segues.settingsToChange {
            let vc = segue.destination as! SettingsChangeViewController
            vc.pageTitle = sender as? String
            if (sender as! String) == "Change Name" {
                vc.changeType = .name
            } else {
                vc.changeType = .password
            }
        }
    }
}

// MARK: - Settings table view delegate and data source methods
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.identifier) as! SettingsTableViewCell
        cell.settingTitle.text = settingsItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // first, deselect table cell
        tableView.deselectRow(at: indexPath, animated: true)
        
        if settingsItems[indexPath.row] == "Log Out" {
            // log out current user
            do {
                try Auth.auth().signOut()
            } catch {
                let alert = UIAlertController(title: "Error", message: "There was a problem signing out. Please try again later.", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
                return
            }
            self.navigationController?.popToRootViewController(animated: true)
        } else if settingsItems[indexPath.row] == "Delete Account" {
            let actionAlert = UIAlertController(title: "Are you sure?", message: "This cannot be reverted", preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: "Delete Account", style: .destructive) { (action) in
                self.deleteAccount()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionAlert.addAction(confirmAction)
            actionAlert.addAction(cancelAction)
            present(actionAlert, animated: true, completion: nil)
        } else {
            // make segue to the change view
            performSegue(withIdentifier: K.Segues.settingsToChange, sender: settingsItems[indexPath.row])
        }
    }
    
    /**
     Performs the following steps and deletes the current user's account.
     
     1. First, it reauthenticates the current user with the password provided by the user.
     2. If reauthentication is successful, the user's data on Firestore is deleted using `Auth.auth().currentUser?.uid`
     3. If data deletion is successful, the entire user is deleted from Firebase Auth.
     4. If user deletion is successful, alert message is displayed and view is popped back to the root.
     */
    private func deleteAccount() {
        // first, confirm password
        let passwordPrompt = UIAlertController(title: "Please type in your password", message: "", preferredStyle: .alert)
        var passwordfield: UITextField = UITextField()
        passwordPrompt.addTextField { (tf) in
            tf.placeholder = "Password"
            tf.isSecureTextEntry = true
            tf.textContentType = .password
            tf.clearButtonMode = .whileEditing
            passwordfield = tf
        }
        let deleteAction = UIAlertAction(title: "Delete", style: .default) { (action) in
            let user = Auth.auth().currentUser
            let credential = EmailAuthProvider.credential(withEmail: user!.email!, password: passwordfield.text!)
            
            user?.reauthenticate(with: credential, completion: { (authResult, error) in
                if error != nil {
                    // error happened
                    self.displayAccountDeleteAlert(title: "Failed to delete account", message: "Please try again later")
                } else {
                    // if password is correct, delete current user's data from the Firestore db
                    let db = Firestore.firestore()
                    let userId = user?.uid
                    db.collection("users").document(userId!).delete() { err in
                        if err != nil {
                            self.displayAccountDeleteAlert(title: "Failed to delete account", message: "Please try again later")
                        } else {
                            // delete user from Firebase Auth
                            user?.delete(completion: { (error) in
                                if error != nil {
                                    self.displayAccountDeleteAlert(title: "Failed to delete account", message: "Please try again later")
                                } else {
                                    // account successfully deleted
                                    
                                    // clear keychain credential
                                    let keychain = KeychainSwift()
                                    keychain.clear()
                                    // clear UserDefaults email
                                    UserDefaults.standard.setValue("", forKey: "email")
                                    // display success message
                                    let confirmationAlert = UIAlertController(title: "Account deleted!", message: "", preferredStyle: .alert)
                                    let action = UIAlertAction(title: "OK", style: .default) { (action) in
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                    confirmationAlert.addAction(action)
                                    self.present(confirmationAlert, animated: true, completion: nil)
                                }
                            })
                        }
                    }
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        passwordPrompt.addAction(deleteAction)
        passwordPrompt.addAction(cancelAction)
        present(passwordPrompt, animated: true, completion: nil)
    }
    
    /**
     Displays the alert controller with passed in title and message.
     The alert will contain the one `OK` button.
     - Parameter title: title of the alert
     - Parameter message: message of the alert
     */
    private func displayAccountDeleteAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
