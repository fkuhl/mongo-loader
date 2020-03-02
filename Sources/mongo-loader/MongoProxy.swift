//
//  File.swift
//  
//
//  Created by Frederick Kuhl on 11/26/19.
//

import Foundation
import MongoSwift
import PMDataTypes

class MongoProxy {
    private let client: MongoClient
    private let db: MongoDatabase
    private let collection: MongoCollection<Document>
    private let decoder: BSONDecoder = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let d = BSONDecoder()
        d.dateDecodingStrategy = .formatted(formatter)
        return d
    }()
    
    /**
     Sets up the structures for the proxy.
     This succeeds even if there is no DB server to connect to.
     So 'twould be a good idea to use, say, count() to check the connection.
     */
    init(collectionName: CollectionName) {
        client = try! MongoClient("mongodb://localhost:27017")
        db = client.db("PeriMeleon")
        collection = db.collection(collectionName.rawValue)
    }

    func add(dataValue: HouseholdDocument) throws -> Id? {
        //logger.debug("about to encode doc")
        do {
            let document = try Document(fromJSON: dataValue.asJSONData())
            //logger.debug("about to insert")
            if let result = try collection.insertOne(document) {
                let idAsBson = result.insertedId
                guard idAsBson.type == BSONType.objectId else {
                    throw MongoProxyError.invalidId("returned id of unexpected type \(idAsBson.type)")
                }
                guard let idAsObjectId = idAsBson.objectIdValue else {
                    logger.error("couldn't convert id")
                    return nil
                }
                let idString = idAsObjectId.hex
                //logger.debug("insert returned id \(idString) of type \(idAsBson.type)")
                return idString
            }
            //logger.debug("add returned nil")
            return nil
        } catch let error as UserError {
            throw MongoProxyError.jsonEncodingError(error)
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }

    func replace(id: Id, newValue: HouseholdDocument) throws -> Bool {
        guard let idValue = ObjectId(id) else {
            throw MongoProxyError.invalidId(id)
        }
        do {
            let filter: Document = ["_id": BSON.objectId(idValue)]
            let documentToUpdateTo = try Document(fromJSON: newValue.asJSONData())
            //NSLog("about to update \(id)")
            let rawResult = try collection.replaceOne(
                filter: filter,
                replacement: documentToUpdateTo,
                options: ReplaceOptions(upsert: false)) //don't insert if not present
            guard let result = rawResult else {
                return false
            }
            return result.matchedCount == 1
        } catch let error as UserError {
            throw MongoProxyError.jsonEncodingError(error)
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }

    func drop() throws {
        do {
            try collection.drop()
        } catch {
            throw MongoProxyError.mongoSwiftError(error)
        }
    }
}

enum MongoProxyError: Error {
    //MongoSwift can't make this string into an ID
    case invalidId(String)
    //Error encoding JSON into BSON Document to pass to MongoSwift
    case jsonEncodingError(Error)
    //Error decoding stuff received from MongoSwift into JSON
    case jsonDecodingError(Error)
    //Other error generated by MongoSwift
    case mongoSwiftError (Error)
}
