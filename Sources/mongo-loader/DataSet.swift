//
//  DataSet.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

typealias Id = String

protocol ValueType: Encodable, Decodable { }

extension ValueType {
    func asJSONData() -> Data  {
        return try! jsonEncoder.encode(self)
    }
}

protocol DataType: Encodable, Decodable {
    associatedtype V: ValueType
    
    var id: Id { get }
    var value: V { get }
}

struct DataSet: Encodable, Decodable {
    let members: [Member]
    let households: [Household]
    let addresses: [Address]
}
