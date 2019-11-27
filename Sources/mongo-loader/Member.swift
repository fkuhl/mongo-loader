//
//  Member.swift
//  
//
//  Created by Frederick Kuhl on 11/13/19.
//

import Foundation

enum TransactionType: String, Encodable, Decodable {
    case BIRTH
    case PROFESSION
    case RECEIVED
    case SUSPENDED
    case SUSPENSION_LIFTED
    case EXCOMMUNICATED
    case RESTORED
    case DISMISSAL_PENDING
    case DISMISSED
    case REMOVED_ADMIN
    case DIED
}

struct Transaction: Encodable, Decodable {
    let index: Id
    let date: Date?
    let type: TransactionType
    let authority: String?
    let church: String?
    let comment: String?
}

enum ServiceType: String, Encodable, Decodable {
    case ORDAINED_TE
    case ORDAINED_RE
    case ORDAINED_DE
    case INSTALLED_TE
    case INSTALLED_RE
    case INSTALLED_DE
    case REMOVED
    case EMERITUS
    case HON_RETIRED
    case DEPOSED
}

struct Service: Encodable, Decodable {
    let index: Id
    let date: Date?
    let type: ServiceType
    let place: String?
    let comment: String?
}

enum Sex: String, Encodable, Decodable {
    case MALE
    case FEMALE
}

enum MemberStatus: String, Encodable, Decodable {
    case NONCOMMUNING
    case COMMUNING
    case ASSOCIATE
    case EXCOMMUNICATED
    case SUSPENDED
    case DISMISSAL_PENDING
    case DISMISSED
    case REMOVED
    case DEAD
    case PASTOR
}

enum MaritalStatus: String, Encodable, Decodable {
    case SINGLE
    case MARRIED
    case DIVORCED
}

struct Member: DataType {
    let id: Id
    let value: MemberValue
}

struct MemberValue: ValueType {
    let familyName: String
    let givenName: String
    let middleName: String?
    let previousFamilyName: String?
    let nameSuffix: String?
    let title: String?
    let nickName: String?
    let sex: Sex
    let dateOfBirth: Date?
    let placeOfBirth: String?
    let status: MemberStatus
    let resident: Bool
    let exDirectory: Bool
    var household: Id
    var tempAddress: Id?
    let transactions: [Transaction]
    let maritalStatus: MaritalStatus
    let spouse: String?
    let dateOfMarriage: Date?
    let divorce: String?
    var father: Id?
    var mother: Id?
    let eMail: String?
    let workEMail: String?
    let mobilePhone: String?
    let workPhone: String?
    let education: String?
    let employer: String?
    let baptism: String?
    let services: [Service]
    let dateLastChanged: Date?
}
