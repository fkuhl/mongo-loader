//
//  Address.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

struct Address: Encodable, Decodable {
    struct Value: Encodable, Decodable {
        let address: String
        let address2: String?
        let city: String
        let state: String?
        let postalCode: String
        let country: String?
        let eMail: String?
        let homePhone: String?
    }
    
    let id: Id
    let value: Value
}
