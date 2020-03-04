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

/**
 DEAD members must still belong to a household, to be included in the denormalized data.
 As DEAD members are imported they are added to mansionInTheSky.
 And of course each household must have a head.
 */
let mansionInTheSkyTempId = UUID().uuidString
var goodShepherd = Member()
goodShepherd.id = UUID().uuidString
goodShepherd.familyName = "Shepherd"
goodShepherd.givenName = "Good"
goodShepherd.placeOfBirth = "Bethlehem"
goodShepherd.status = .PASTOR //not counted against communicants
goodShepherd.resident = false //not couned against residents
goodShepherd.exDirectory = true //not included in directory
goodShepherd.household = mansionInTheSkyTempId

var mansionInTheSky = HouseholdDocument()
mansionInTheSky.head = goodShepherd
mansionInTheSky.id = mansionInTheSkyTempId


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
        e.household = v.household == nil ? mansionInTheSkyTempId : v.household!
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
 - Postcondition: HouseholdDocument structures created, with Members and Addresses embedded. Members have imported Household indexes, not in Mongo yet. mansionInTheSky has been appended to array of HouseholdDocuments.
 */
func indexHouseholds(_ households: [HouseholdImported],
                     addressesByImportedIndex: [Id:Address],
                     membersByImportedIndex: [Id:Member]) throws -> [HouseholdDocument] {
    var i = 0
    var householdDocs: [HouseholdDocument] = try households.map { hi in
        var hd = HouseholdDocument()
        hd.id = hi.id
        guard let head = membersByImportedIndex[hi.value.head] else {
            throw BadData(message: "no Member imported for head \(hi.value.head) of household \(hi.id)")
        }
        hd.head = head
        if let spouseIndex = hi.value.spouse {
            guard let spouse = membersByImportedIndex[spouseIndex] else {
                throw BadData(message: "no Member imported for spouse \(spouseIndex) of household \(hi.id)")
            }
            hd.spouse = spouse
        } else {
            hd.spouse = nil
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
        hd.others = others
        if let ai = hi.value.address {
            guard let address = addressesByImportedIndex[ai] else {
                throw BadData(message: "no Address imported for address \(ai) of household \(hi.id)")
            }
            hd.address = address
        } else {
            hd.address = nil
        }
        if i % 10 == 0 {
            logger.info("household \(hd.head.fullName())")
        }
        i += 1
        return hd
    }
    for member in membersByImportedIndex.values {
        if member.household == mansionInTheSkyTempId {
            mansionInTheSky.others.append(member)
            logger.debug("placing \(member.fullName()) in mansionInTheSky")
        }
    }
    householdDocs.append(mansionInTheSky)
    return householdDocs
}

/**
 Store preliminary version of HouseholdDocuments in Mongo, creating an index
 from imported household index to MongDB index.
 Also create new set of HouseholdDocuments with mongo index stored in them.
 */
func store(data: [HouseholdDocument]) throws -> ([Id: Id], [HouseholdDocument]) {
    var mongoIndexByInputIndex = [Id: Id]()
    let proxy = MongoProxy(collectionName: CollectionName.households)
    do {
        try proxy.drop()
        logger.info("dropped collection \(CollectionName.households)")
    } catch {
        //drop will toss you a "ns not found" error if the collection doesn't exist. Drive on.
        logger.error("drop failed on \(CollectionName.households), err: \(error)")
    }
    var seq = 0
    let docsWithIndex: [HouseholdDocument] = try data.map {
        var indexedDoc = $0
        let importedIndex = $0.id
        if let mongoId = try proxy.add(dataValue: $0) {
            mongoIndexByInputIndex[importedIndex] = mongoId
            indexedDoc.id = mongoId
            //if seq % 50 == 0 {
                logger.info("Household id '\(importedIndex)' stored as \(mongoId)")
            //}
        }
        seq = seq + 1
        return indexedDoc
    }
    return (mongoIndexByInputIndex, docsWithIndex)
}

/**
 Fixup HouseholdDocuments: In each Member, replace the imported Household index with the Mongo-assigned.
 - Precondition: mongoIndexByImportedIndex is populated.
 - Postcondition: HouseholdDocuments are stored in final form.
 */
func fixupAndUpdate(data: [HouseholdDocument], mongoIndexByImportedIndex: [Id: Id]) throws -> [HouseholdDocument] {
    let proxy = MongoProxy(collectionName: CollectionName.households)
    let updatedSet: [HouseholdDocument] = try data.map { hd in
        //For each member, head, spouse others, update the household id now that we know it
        var updated = hd
        guard let headMongo = mongoIndexByImportedIndex[hd.head.household] else {
            throw BadData(message: "head of \(hd.head.fullName()) has no Mongo household index corresp to '\(hd.head.household)'")
        }
        updated.head.household = headMongo
        if let spouse = hd.spouse {
            guard let spouseMongo = mongoIndexByImportedIndex[spouse.household] else {
                throw BadData(message: "spouse of \(spouse.fullName()) has no Mongo household index corresp to \(spouse.household)")
            }
            updated.spouse?.household = spouseMongo
        }
        let updatedOthers: [Member] = try hd.others.map { other in
            var updatedOther = other
            guard let otherMongo = mongoIndexByImportedIndex[other.household] else {
                throw BadData(message: "other \(other.fullName()) has no Mongo household index corresp to \(other.household)")
            }
            updatedOther.household = otherMongo
            return updatedOther
        }
        updated.others = updatedOthers
        //update in mongo
        let succeeded = try proxy.replace(id: updated.id, newValue: updated)
        if !succeeded {
            logger.error("update failed of household \(updated.head.fullName()), id: \(updated.id)")
        }
        return updated
    }
    return updatedSet
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
    let householdDocsReadyToStore = try indexHouseholds(dataSet.households,
                                                        addressesByImportedIndex: addressesByImportedIndex,
                                                        membersByImportedIndex: membersByImportedIndex)
    let (mongoIndexByImportedIndex, storedDocs) = try store(data: householdDocsReadyToStore)
//    for (importedIndex, storedIndex) in mongoIndexByImportedIndex {
//        logger.info("imported: '\(importedIndex)' stored: '\(storedIndex)'")
//    }
    let updatedSet = try fixupAndUpdate(data: storedDocs,
              mongoIndexByImportedIndex: mongoIndexByImportedIndex)
    var j = 0
    updatedSet.forEach { hd in
        if j % 10 == 0 {
            logger.info("id \(hd.id) is \(hd.head.fullName())")
        }
        j += 1
    }
    logger.info("And we're done.")
} catch {
    logger.error("\(error)")
}

