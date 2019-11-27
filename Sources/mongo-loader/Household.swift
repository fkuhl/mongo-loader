//
//  Household.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

struct Household: DataType {
    let id: Id
    let value: HouseholdValue
}

struct HouseholdValue: ValueType {
    var head: Id? //this would have to be an error
    var spouse: Id?
    var others: [Id]
    var address: Id
}
