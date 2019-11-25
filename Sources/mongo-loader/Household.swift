//
//  Household.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

struct Household: Encodable, Decodable {
    struct Value: Encodable, Decodable {
        let head: Id? //this would have to be an error
        let spouse: Id?
        let others: [Id]
        let address: Id
    }
    
    let id: Id
    let value: Value
}
