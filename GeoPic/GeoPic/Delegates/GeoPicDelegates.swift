//
//  GeoPicDelegates.swift
//  GeoPic
//
//  Created by John Choi on 3/13/21.
//

import Foundation

protocol AuthenticationDelegate {
    
    /**
     A delegate method that gets called when the user creation operation is finished.
     - Parameter userCreated: true if user has been created successfully
     - Parameter email: Email of the new user
     - Parameter name: Name of the new user
     */
    func authenticationDelegate(_ userCreated: Bool, email: String, name: String)
}

protocol PictureViewDelegate {
    
    /**
     A delegate method that gets called when the pin has a invalid author (either deleted user or simply nil).
     - Parameter pin: pin to be deleted
     - Parameter isInvalidPin: true if the pin is invalid
     */
    func pictureViewDelegate(for pin: Pin, _ isInvalidPin: Bool)
}
