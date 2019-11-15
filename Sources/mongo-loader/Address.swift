//
//  Address.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

struct Address: Encodable, Decodable {
    let _id: Id
    let address: String
    let address2: String?
    let city: String
    let state: String?
    let postalCode: String
    let country: String?
    let eMail: String?
    let homePhone: String?
}
