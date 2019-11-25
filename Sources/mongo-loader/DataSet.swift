//
//  DataSet.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

typealias Id = String

struct DataSet: Encodable, Decodable {
    let members: [Member]
    let households: [Household]
    let addresses: [Address]
}
