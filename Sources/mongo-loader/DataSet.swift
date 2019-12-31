//
//  DataSet.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation
import PMDataTypes

struct DataSet: Encodable, Decodable {
    let members: [Member]
    let households: [Household]
    let addresses: [Address]
}
