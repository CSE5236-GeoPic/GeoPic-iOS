//
//  SettingsViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/28/21.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {

    @IBOutlet weak var table: UITableView!
    
    // list of settings available
    let settingsItems: [String] = ["Change Name", "Change Password", "Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // table setup
        table.dataSource = self
        table.delegate = self
        // register table cell to display on table
        table.register(SettingsTableViewCell.nib, forCellReuseIdentifier: SettingsTableViewCell.identifier)
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
        } else {
            // make segue to the change view
            performSegue(withIdentifier: K.Segues.settingsToChange, sender: settingsItems[indexPath.row])
        }
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

#warning("Debug purpose methods. Delete when ready to deploy")
extension SettingsViewController {
    
    private func displayAlert(action: String) {
        let alert = UIAlertController(title: "Work In Progress", message: "Action of <\(action)> happens here", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
