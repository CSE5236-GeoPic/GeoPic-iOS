//
//  SettingsTableViewCell.swift
//  GeoPic
//
//  Created by John Choi on 2/28/21.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    
    static let identifier = "settingsCell"
    static let nib = UINib(nibName: "SettingsTableViewCell", bundle: nil)

    @IBOutlet weak var settingTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
