//
//  File.swift
//
//
//  Created by Frederick Kuhl on 2/28/20.
//

import Foundation
import PMDataTypes
import Logging

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

//var addressesByImportedIndex = [Id : Address]()
//var membersByImportedIndex = [Id : Member]()
//var householdsByImportedIndex = [Id : HouseholdDocument]()
//var mongoIndexByImportedIndex = [Id : Id]()

struct BadData: Error {
    var message: String
}

func nilEmpty(_ s: String?) -> String? {
    if let t = s {
        return t.isEmpty ? nil : t
    }
    return nil
}

func indexAddresses(_ addresses: [AddressImported]) -> [Id : Address] {
    var i = 0
    var index = [Id : Address]()
    for a in addresses {
        var edited = a.value
        edited.address2 = nilEmpty(edited.address2)
        edited.country = nilEmpty(edited.country)
        edited.eMail = nilEmpty(edited.eMail)
        edited.homePhone = nilEmpty(edited.homePhone)
        index[a.id] = edited
        if i % 10 == 0 {
            logger.info("address \(edited.address), \(edited.city)")
        }
        i += 1
    }

    return index
}

/**
 Create collection of Member structs indexed by member's imported index.
 
 - Precondition: Addresses have been indexed, i.e., indexAddresses has been executed.
 - Postcondition: Member structures have any tempAddresses embedded. Household index is still the imported index, not the Mongo.
 */
func indexMembers(_ members: [MemberImported],
                  addressesByImportedIndex: [Id:Address]) -> [Id : Member] {
    var index = [Id : Member]()
    var i = 0
    for m in members {
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
        if let taIndex = v.tempAddress {
            if let ta = addressesByImportedIndex[taIndex] {
                e.tempAddress = ta
                logger.info("member \(e.fullName()) had tempAddress \(ta.address), \(ta.city)")
            } else {
                logger.error("temp addr index \(taIndex) but no entry")
            }
        } else {
            e.tempAddress = nil
        }
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
        if i % 10 == 0 {
            logger.info("member \(e.fullName())")
        }
        i += 1
    }

    return index
}

/**
 Create collection of HouseholdDocument structs indexed by household's imported index. HouseholdDocuments are ready to be added to Mongo.
 
 - Precondition: Members have been indexed, i.e., indexMembers has been executed.
 - Postcondition: HouseholdDocument structures created, with Members and Addresse embedded. Members have imported Household indexes, not Mongo yet.
 */
func indexHouseholds(_ households: [HouseholdImported],
                     addressesByImportedIndex: [Id:Address],
                     membersByImportedIndex: [Id:Member]) throws -> [Id : HouseholdDocument] {
    var i = 0
    var index = [Id : HouseholdDocument]()
    for hi in households {
        var hv = HouseholdDocumentValue()
        guard let head = membersByImportedIndex[hi.value.head] else {
            throw BadData(message: "no Member imported for head \(hi.value.head) of household \(hi.id)")
        }
        hv.head = head
        if let spouseIndex = hi.value.spouse {
            guard let spouse = membersByImportedIndex[spouseIndex] else {
                throw BadData(message: "no Member imported for spouse \(spouseIndex) of household \(hi.id)")
            }
            hv.spouse = spouse
        } else {
            hv.spouse = nil
        }
        var others = [Member]()
        for oi in hi.value.others { //any nils in import are ignored!
            if let other = membersByImportedIndex[oi] {
                others.append(other)
            } else {
                //log it and drive on--problem with the data
                logger.error("no Member imported for other \(oi) of household \(hi.id)")
            }
        }
        hv.others = others
        if let ai = hi.value.address {
            guard let address = addressesByImportedIndex[ai] else {
                throw BadData(message: "no Address imported for address \(ai) of household \(hi.id)")
            }
            hv.address = address
        } else {
            hv.address = nil
        }
        index[hi.id] = HouseholdDocument(id: hi.id, value: hv)
        if i % 10 == 0 {
            logger.info("household \(hv.head.fullName())")
        }
        i += 1
    }
    return index
}

/**
 Store prelimiary version of HouseholdDocuments in Mongo, creating an index
 from imported household index to MongDB index.
 */
func store(data: [HouseholdDocument]) throws -> [Id: Id] {
    var mongoIndexByInputIndex = [Id: Id]()
    let proxy = MongoProxy(collectionName: CollectionName.households)
    do {
        try proxy.drop()
    } catch {
        //drop will toss you a "ns not found" error if the collection doesn't exist. Drive on.
        logger.error("drop failed on \(CollectionName.households), err: \(error)")
    }
    var seq = 0
    try data.forEach {
        if let mongoId = try proxy.add(dataValue: $0.value) {
            let stringified = stringify($0.id)
            mongoIndexByInputIndex[stringified] = mongoId
            if seq % 50 == 0 {
                logger.info("Household id \($0.id) stored as \(mongoId)")
            }
        }
        seq = seq + 1
    }
    return mongoIndexByInputIndex
}

/**
 Fixup HouseholdDocuments: In each Member, replace the imported Household index with the Mongo-assigned.
 - Precondition: mongoIndexByImportedIndex is populated.
 - Postcondition: HouseholdDocuments are in final form for storage.
 */
func fixup() throws {
    
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
    let addressesByImportedIndex = indexAddresses(dataSet.addresses)
    let membersByImportedIndex = indexMembers(dataSet.members,
                                              addressesByImportedIndex: addressesByImportedIndex)
    let householdsByImportedIndex = try indexHouseholds(dataSet.households,
                                                        addressesByImportedIndex: addressesByImportedIndex,
                                                        membersByImportedIndex: membersByImportedIndex)
    let householdsToStore = [HouseholdDocument](householdsByImportedIndex.values)
    let mongoIndexByImportedIndex = try store(data: householdsToStore)
    try fixup()
} catch {
    logger.error("\(error)")
}

