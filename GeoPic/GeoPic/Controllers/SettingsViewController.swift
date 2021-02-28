//
//  SettingsViewController.swift
//  GeoPic
//
//  Created by John Choi on 2/28/21.
//

import UIKit

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
        table.register(SettingsTableViewCell().nib, forCellReuseIdentifier: SettingsTableViewCell().identifier)
    }


}

// MARK: - Settings table view delegate and data source methods
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell().identifier) as! SettingsTableViewCell
        cell.settingTitle.text = settingsItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // first, deselect table cell
        tableView.deselectRow(at: indexPath, animated: true)
        // perform segue or action
        displayAlert(action: settingsItems[indexPath.row])
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
