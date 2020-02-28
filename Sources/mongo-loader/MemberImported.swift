//
//  MemberImported.swift
//  
//
//  Created by Frederick Kuhl on 2/27/20.
//

import Foundation
import PMDataTypes

/**
 A member, communing or noncommuning.
 As imported
 */

public struct MemberImported: Codable {
    public var id: Id
    public var value: MemberImportedValue
    
    public init(id: Id, value: MemberImportedValue) {
        self.id = id
        self.value = value
    }
}

/** Default values are merely to aid making mock objects. */
public struct MemberImportedValue: Codable {
    public var familyName: String
    public var givenName: String
    public var middleName: String?
    public var previousFamilyName: String?
    public var nameSuffix: String?
    public var title: String?
    public var nickName: String?
    public var sex: Sex
    public var dateOfBirth: Date?
    public var placeOfBirth: String?
    public var status: MemberStatus = MemberStatus.COMMUNING
    public var resident: Bool = true
    public var exDirectory: Bool = false
    public var household: Id? //nil if member is DEAD
    public var tempAddress: Id?
    public var transactions: [Transaction] = []
    public var maritalStatus: MaritalStatus = MaritalStatus.MARRIED
    public var spouse: String?
    public var dateOfMarriage: Date?
    public var divorce: String?
    public var father: Id?
    public var mother: Id?
    public var eMail: String?
    public var workEMail: String?
    public var mobilePhone: String?
    public var workPhone: String?
    public var education: String?
    public var employer: String?
    public var baptism: String?
    public var services: [Service] = []
    public var dateLastChanged: Date? = nil
    
//    /** just for mocking */
////    public init(
////        familyName: String,
////        givenName: String,
////        middleName: String?,
////        previousFamilyName: String?,
////        nickName: String?,
////        sex: Sex,
////        household: Id,
////        eMail: String?,
////        mobilePhone: String?,
////        education: String?,
////        employer: String?,
////        baptism: String?
////    ) {
////        self.familyName = familyName
////        self.givenName = givenName
////        self.middleName = middleName
////        self.previousFamilyName = previousFamilyName
////        self.nickName = nickName
////        self.sex = sex
////        self.household = household
////        self.eMail = eMail
////        self.mobilePhone = mobilePhone
////        self.education = education
////        self.employer = employer
////        self.baptism = baptism
////    }
//    
//    /** A function, not computed property, because a computed property interferes with encoding and decoding. */
//    public func fullName() -> String {
//        let previousContribution = nugatory(previousFamilyName) ? "" : " (\(previousFamilyName!))"
//        let nickContribution = nugatory(nickName) ? "" : " \"\(nickName!)\""
//        let middleContribution = nugatory(middleName) ? "" : " \(middleName!)"
//        return "\(familyName), \(givenName)\(middleContribution)\(previousContribution)\(nickContribution)"
//    }
}
//
//    fileprivate func nugatory(_ thing: String?) -> Bool {
//        return thing == nil || thing == ""
//    }
