//
//  Pin.swift
//  GeoPic
//
//  Created by Dave Becker on 2/25/21.
//

import Foundation
import MapKit

class Pin: NSObject, MKAnnotation {
    let id: String?
    let image: UIImage?
    let coordinate: CLLocationCoordinate2D
    let score: UInt?
    let userID: String?
    let date: Date?

    init(
        id: String?,
        image: UIImage?,
        coordinate: CLLocationCoordinate2D,
        score: UInt?,
        userID: String?,
        date: Date?
    ) {
        self.score = score
        self.userID = userID
        self.coordinate = coordinate
        self.image = image
        self.id = id
        self.date = date
        super.init()
    }
}