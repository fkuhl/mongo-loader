import Foundation
import PMDataTypes

struct Globals {
    var dataSet: DataSet
    var memberIndexes: [Id: Id]
    var householdIndexes: [Id: Id]
    var addressIndexes: [Id: Id]
}

func store<D: DataType>(data:[D], inCollection collectionName: CollectionName) throws -> [Id: Id] {
    var mongoIndexByInputIndex = [Id: Id]()
    let proxy = MongoProxy(collectionName: collectionName)
    do {
        try proxy.drop()
    } catch {
        //drop will toss you a "ns not found" error if the collection doesn't exist. Drive on.
        NSLog("drop failed on collection \(collectionName), err: \(error)")
    }
    try data.forEach {
        if let mongoId = try proxy.add(dataValue: $0.value) {
            mongoIndexByInputIndex[$0.id] = mongoId
        }
    }
    return mongoIndexByInputIndex
}

func updateMembers(globals: Globals) throws {
    let proxy = MongoProxy(collectionName: .members)
    var seq = 0
    try globals.dataSet.members.forEach {
        guard let mongoIndex = globals.memberIndexes[$0.id] else {
            NSLog("can't find old member index \($0.id) to update")
            exit(1)
        }
        var value = $0.value
        if let householdIndex = value.household {
            if let householdMongoIndex = globals.householdIndexes[householdIndex] {
                value.household = householdMongoIndex
            }
        } else {
            NSLog("Nil household for \(value.familyName), \(value.givenName)")
        }
        if let tempAddress = value.tempAddress {
            if let tempAddressMongoIndex = globals.addressIndexes[tempAddress] {
                value.tempAddress = tempAddressMongoIndex
            }
        }
        if let father = value.father {
            if let fatherMongoIndex = globals.memberIndexes[father] {
                value.father = fatherMongoIndex
            }
        }
        if let mother = value.mother {
            if let motherMongoIndex = globals.memberIndexes[mother] {
                value.mother = motherMongoIndex
            }
        }
        if let middleName = value.middleName {
            if middleName.isEmpty { value.middleName = nil }
        }
        if let prev = value.previousFamilyName {
            if prev.isEmpty { value.previousFamilyName = nil }
        }
        if let suff = value.nameSuffix {
            if suff.isEmpty { value.nameSuffix = nil }
        }
        if let title = value.title {
            if title.isEmpty { value.title = nil }
        }
        if let nick = value.nickName {
            if nick.isEmpty { value.nickName = nil }
        }
        if let place = value.placeOfBirth {
            if place.isEmpty { value.placeOfBirth = nil }
        }
        if let spouse = value.spouse {
            if spouse.isEmpty { value.spouse = nil }
        }
        if let div = value.divorce {
            if div.isEmpty { value.divorce = nil }
        }
        if let em = value.eMail {
            if em.isEmpty { value.eMail = nil }
        }
        if let wo = value.workEMail {
            if wo.isEmpty { value.workEMail = nil }
        }
        if let mob = value.mobilePhone {
            if mob.isEmpty { value.mobilePhone = nil }
        }
        if let wo = value.workPhone {
            if wo.isEmpty { value.workPhone = nil }
        }
        if let ed = value.education {
            if ed.isEmpty { value.education = nil }
        }
        if let em = value.employer {
            if em.isEmpty { value.employer = nil }
        }
        if let bap = value.baptism {
            if bap.isEmpty { value.baptism = nil }
        }
        if try proxy.replace(id: mongoIndex, newValue: value) {
            NSLog("updated member \(mongoIndex)")
            if seq % 50 == 0 {
                let valRep = try jsonEncoder.encode(value)
                print(String(data: valRep, encoding: .utf8)!)
            }
            seq += 1
        } else {
            NSLog("replacing new index \(mongoIndex) failed")
        }
    }
}

func updateHouseholds(globals: Globals) throws {
    let proxy = MongoProxy(collectionName: .households)
    try globals.dataSet.households.forEach {
        var seq = 0
        guard let mongoIndex = globals.householdIndexes[$0.id] else {
            NSLog("can't find old household index \($0.id) to update")
            exit(1)
        }
        var value = $0.value
        if let headMongoIndex = globals.memberIndexes[value.head] {
            value.head = headMongoIndex
        }
        if let spouse = value.spouse {
            if let spouseMongoIndex = globals.memberIndexes[spouse] {
                value.spouse = spouseMongoIndex
            }
        }
        if let address = value.address, let addressMongoIndex = globals.addressIndexes[address] {
            value.address = addressMongoIndex
        }
        value.others = value.others.map {
            globals.memberIndexes[$0] ?? ""
        }
        if try proxy.replace(id: mongoIndex, newValue: value) {
            NSLog("updated household \(mongoIndex)")
            if seq % 10 == 0 {
                let valRep = try jsonEncoder.encode(value)
                print(String(data: valRep, encoding: .utf8)!)
            }
            seq += 1
        } else {
            NSLog("replacing new index \(mongoIndex) failed")
        }
    }
}

print("starting...")

guard let url = URL(string: "file:///Users/fkuhl/Desktop/members.json") else {
    NSLog("URL failed")
    exit(1)
}
do {
    let data = try Data(contentsOf: url)
    let dataSet = try jsonDecoder.decode(DataSet.self, from: data)
    NSLog("\(dataSet.members.count) mem, \(dataSet.households.count) households, \(dataSet.addresses.count) addrs")
    let householdIndexes = try store(data: dataSet.households, inCollection: .households)
    NSLog("\(householdIndexes.count) households stored")
    let memberIndexes = try store(data: dataSet.members, inCollection: .members)
    NSLog("\(memberIndexes.count) members stored")
    let addressIndexes = try store(data: dataSet.addresses, inCollection: .addresses)
    NSLog("\(addressIndexes.count) addresses stored")
    let globals = Globals(dataSet: dataSet,
                          memberIndexes: memberIndexes,
                          householdIndexes: householdIndexes,
                          addressIndexes: addressIndexes)
    
    //At this point we have all records stored, but they contain "old" indexes.
    try updateMembers(globals: globals)
    try updateHouseholds(globals: globals)
} catch {
    NSLog("error: \(error)")
}


