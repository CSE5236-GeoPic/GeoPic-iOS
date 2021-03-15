//
//  AuthenticationDelegate.swift
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
