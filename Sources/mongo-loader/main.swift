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
        if let householdMongoIndex = globals.householdIndexes[value.household] {
            value.household = householdMongoIndex
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
        if let head = value.head {
            if let headMongoIndex = globals.memberIndexes[head] {
                value.head = headMongoIndex
            }
        }
        if let spouse = value.spouse {
            if let spouseMongoIndex = globals.memberIndexes[spouse] {
                value.spouse = spouseMongoIndex
            }
        }
        if let addressMongoIndex = globals.addressIndexes[value.address] {
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


