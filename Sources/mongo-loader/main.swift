//
//  File.swift
//
//
//  Created by Frederick Kuhl on 2/28/20.
//

import Foundation
import PMDataTypes
import Logging

func nilEmpty(_ s: String?) -> String? {
    if let t = s {
        return t.isEmpty ? nil : t
    }
    return nil
}

func indexAddresses(from dataSet: DataSet) -> [Id : Address] {
    var index = [Id : Address]()
    for a in dataSet.addresses {
        var edited = a.value
        edited.address2 = nilEmpty(edited.address2)
        edited.country = nilEmpty(edited.country)
        edited.eMail = nilEmpty(edited.eMail)
        edited.homePhone = nilEmpty(edited.homePhone)
        index[a.id] = edited
    }

    return index
}

func indexMembers(from dataSet: DataSet) -> [Id : Member] {
    var index = [Id : Member]()
    for m in dataSet.members {
        let v = m.value
        var e = Member()
        e.familyName = v.familyName
        e.givenName = v.givenName
        e.middleName = nilEmpty(v.middleName)
        e.previousFamilyName = nilEmpty(v.previousFamilyName)
        e.nameSuffix = nilEmpty(v.nameSuffix)
        e.title = nilEmpty(v.title)
        e.nickName = nilEmpty(v.nickName)
        e.dateOfBirth = v.dateOfBirth
        e.placeOfBirth = nilEmpty(v.placeOfBirth)
        e.status = v.status
        e.resident = v.resident
        e.exDirectory = v.exDirectory
        e.household = v.household
        //TODO
        e.tempAddress = Address()
        e.transactions = v.transactions
        e.maritalStatus = v.maritalStatus
        e.spouse = nilEmpty(v.spouse)
        e.dateOfMarriage = v.dateOfMarriage
        e.divorce = nilEmpty(v.divorce)
        e.father = nilEmpty(v.father)
        e.mother = nilEmpty(v.mother)
        e.eMail = nilEmpty(v.eMail)
        e.workEMail = nilEmpty(v.workEMail)
        e.mobilePhone = nilEmpty(v.mobilePhone)
        e.workPhone = nilEmpty(v.workPhone)
        e.education = nilEmpty(v.education)
        e.employer = nilEmpty(v.employer)
        e.baptism = nilEmpty(v.baptism)
        e.dateLastChanged = v.dateLastChanged
        //TODO edit Trnsactions, Services
        index[m.id] = e
    }

    return index
}

var addressesByImportedIndex = [Id : Address]()
var membersByImportedIndex = [Id : Member]()

LoggingSystem.bootstrap {
    label in
    return StreamLogHandler.standardOutput(label: label)
}
var logger = Logger(label: "com.tamelea.pm.mongo_loader")
logger.logLevel = .debug
if let logLevelEnv = ProcessInfo.processInfo.environment["PM_LOG_LEVEL"],
    let logLevel = Logger.Level(rawValue: logLevelEnv) {
    logger.logLevel = logLevel
    logger.info("Log level set from environment: \(logLevel)")
}

logger.info("starting...")

guard let url = URL(string: "file:///Users/fkuhl/Desktop/members.json") else {
    logger.error("URL failed")
    exit(1)
}
do {
    let data = try Data(contentsOf: url)
    let dataSet = try jsonDecoder.decode(DataSet.self, from: data)
    logger.info("read \(dataSet.members.count) mem, \(dataSet.households.count) households, \(dataSet.addresses.count) addrs")
    addressesByImportedIndex = indexAddresses(from: dataSet)
    membersByImportedIndex = indexMembers(from: dataSet)
} catch {
    logger.error("error: \(error)")
}

