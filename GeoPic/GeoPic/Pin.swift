//
//  Pin.swift
//  GeoPic
//
//  Created by Dave Becker on 2/25/21.
//

import Foundation
import MapKit

class Pin: NSObject, MKAnnotation {
    let image: UIImage?
    let coordinate: CLLocationCoordinate2D
    let score: UInt?
    let userID: String?

    init(
        image: UIImage?,
        coordinate: CLLocationCoordinate2D,
        score: UInt?,
        userID: String?
    ) {
        self.score = score
        self.userID = userID
        self.coordinate = coordinate
        self.image = image
        super.init()
    }
}
