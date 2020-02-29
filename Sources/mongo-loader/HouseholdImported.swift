//
//  HouseholdImported.swift
//  
//
//  Created by Frederick Kuhl on 2/27/20.
//

import Foundation
import PMDataTypes

/**
 A household as imported.
 As you can see, this structure contains nothing but MongoDB ids.
 Single persons each have their own household.
 */
public struct HouseholdImported: Codable {
    public var id: Id
    public var value: HouseholdImportedValue
    
    public init(id: Id, value: HouseholdImportedValue) {
        self.id = id
        self.value = value
    }
}

public struct HouseholdImportedValue: Codable {
    public var head: Id = "" //data cleaned up enough so this isn't ever nil
    public var spouse: Id? = nil
    public var others: [Id] = []
    public var address: Id? = nil //nil if address unknown
    
    public init() { }
    
    /** just for mocking */
//    public init(head: Id, spouse: Id?, others: [Id], address: Id) {
//        self.head = head
//        self.spouse = spouse
//        self.others = others
//        self.address = address
//    }
}
