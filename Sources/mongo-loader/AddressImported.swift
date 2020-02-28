//
//  AddressImported.swift
//  
//
//  Created by Frederick Kuhl on 2/27/20.
//

import Foundation
import PMDataTypes

public struct AddressImported: Codable {
    public init(id: Id, value: Address) {
        self.id = id
        self.value = value
        
    }
    
    public var id: Id
    public var value: Address
}

//public struct AddressImportedValue: ValueType {
//    public var address: String
//    public var address2: String? = nil
//    public var city: String
//    public var state: String?
//    public var postalCode: String
//    public var country: String? = nil
//    public var eMail: String? = nil
//    public var homePhone: String? = nil
//    
//    /** only for mocking */
////    public init(
////        address: String,
////        city: String,
////        state: String?,
////        postalCode: String
////    ) {
////        self.address = address
////        self.city = city
////        self.state = state
////        self.postalCode = postalCode
////    }
//}
