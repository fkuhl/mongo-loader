import Foundation
import PMDataTypes

struct Globals {
    var dataSet: DataSet
    var memberIndexes: [Id: Id]
    var householdIndexes: [Id: Id]
    var addressIndexes: [Id: Id]
}

/** Force ID to be seen as string, despite being numeric. */
func stringify(_ id: String) -> String {
    return "ID" + id
}

func store<D: DataType>(data:[D],
                        inCollection collectionName: CollectionName,
                        editor: (D.V) -> (D.V)) throws -> ([Id: Id], [D]) {
    var mongoIndexByInputIndex = [Id: Id]()
    var editedData = [D]()
    let proxy = MongoProxy(collectionName: collectionName)
    do {
        try proxy.drop()
    } catch {
        //drop will toss you a "ns not found" error if the collection doesn't exist. Drive on.
        NSLog("drop failed on collection \(collectionName), err: \(error)")
    }
    var seq = 0
    try data.forEach {
        let edited = editor($0.value)
        if let mongoId = try proxy.add(dataValue: edited) {
            let stringified = stringify($0.id)
            mongoIndexByInputIndex[stringified] = mongoId
            editedData.append(D(id: stringified, value: edited))
            if seq % 50 == 0 {
                NSLog("coll \(collectionName), id \($0.id) stored as \(mongoId)")
            }
        }
        seq = seq + 1
    }
    return (mongoIndexByInputIndex, editedData)
}

func editMember(_ orig: MemberValue) -> MemberValue {
    var value = orig
    if let householdIndex = value.household {
        value.household = stringify(householdIndex)
    }
    if let tempAddress = value.tempAddress {
        value.tempAddress = stringify(tempAddress)
    }
    if let father = value.father {
        value.father = stringify(father)
    }
    if let mother = value.mother {
        value.mother = stringify(mother)
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
    value.transactions = value.transactions.map { editTransaction($0) }
    value.services = value.services.map { editService($0) }
    return value
}

func editTransaction(_ orig: Transaction) -> Transaction {
    var value = orig
    value.index = stringify(value.index)
    if let authority = value.authority {
        if authority.isEmpty { value.authority = nil }
    }
    if let church = value.church {
        if church.isEmpty { value.church = nil }
    }
    if let comment = value.comment {
        if comment.isEmpty { value.comment = nil }
    }
    return value
}

func editService(_ orig: Service) -> Service {
    var value = orig
    value.index = stringify(value.index)
    if let place = value.place {
        if place.isEmpty { value.place = nil }
    }
    if let comment = value.comment {
        if comment.isEmpty { value.comment = nil }
    }
    return value
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
        value.transactions = value.transactions.map {
            var transaction = $0
            transaction.index = mongoIndex //the (somewhat redundant) index is the member this belongs to
            return transaction
        }
        value.services = value.services.map {
            var service = $0
            service.index = mongoIndex //redundant ditto
            return service
        }
        if try proxy.replace(id: mongoIndex, newValue: value) {
            NSLog("updated member, old ID \($0.id), new ID \(mongoIndex)")
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
    var seq = 0
    try globals.dataSet.households.forEach {
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
        value.others = value.others.compactMap {
            return globals.memberIndexes[$0]
        }
        if try proxy.replace(id: mongoIndex, newValue: value) {
            NSLog("updated household, old ID \($0.id), new \(mongoIndex)")
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

func editHousehold(_ orig: HouseholdValue) -> HouseholdValue {
    var value = orig
    value.head = stringify(value.head)
    if let spouse = value.spouse {
        value.spouse = stringify(spouse)
    }
    value.others = value.others.compactMap {
        if $0.isEmpty { return nil }
        return stringify($0)
    }
    if let address = value.address {
        value.address = stringify(address)
    }
    return value
}

func editAddress(_ orig: AddressValue) -> AddressValue {
    var value = orig
    if let add = value.address2 {
        if add.isEmpty { value.address2 = nil }
    }
    if let state = value.state {
        if state.isEmpty { value.state = nil }
    }
    if let country = value.country {
        if country.isEmpty { value.country = nil }
    }
    if let em = value.eMail {
        if em.isEmpty { value.eMail = nil }
    }
    if let ho = value.homePhone {
        if ho.isEmpty { value.homePhone = nil }
    }
    return orig
}

print("starting...")

guard let url = URL(string: "file:///data/members.json") else {
    NSLog("URL failed")
    exit(1)
}
do {
    let data = try Data(contentsOf: url)
    let dataSet = try jsonDecoder.decode(DataSet.self, from: data)
    NSLog("\(dataSet.members.count) mem, \(dataSet.households.count) households, \(dataSet.addresses.count) addrs")
    let (memberIndexes, editedMembers) = try store(data: dataSet.members,
                                  inCollection: .members,
                                  editor: editMember)
    NSLog("\(memberIndexes.count) members stored")
    let (householdIndexes, editedHouseholds) = try store(data: dataSet.households,
                                     inCollection: .households,
                                     editor: editHousehold)
    NSLog("\(householdIndexes.count) households stored")
    let (addressIndexes, editedAddresses) = try store(data: dataSet.addresses,
                                   inCollection: .addresses,
                                   editor: editAddress)
    NSLog("\(addressIndexes.count) addresses stored")
    let newDataSet = DataSet(members: editedMembers, households: editedHouseholds, addresses: editedAddresses)
    let globals = Globals(dataSet: newDataSet,
                          memberIndexes: memberIndexes,
                          householdIndexes: householdIndexes,
                          addressIndexes: addressIndexes)
    
    //At this point we have all records stored, but they contain "old" indexes.
    try updateMembers(globals: globals)
    try updateHouseholds(globals: globals)
} catch {
    NSLog("error: \(error)")
}


