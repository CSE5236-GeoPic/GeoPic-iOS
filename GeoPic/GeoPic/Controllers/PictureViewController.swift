//
//  PictureViewController.swift
//  GeoPic
//
//  Created by Dave Becker on 2/25/21.
//

import UIKit

class PictureViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    
    var pin: Pin?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(pin?.id!)

    }

}
