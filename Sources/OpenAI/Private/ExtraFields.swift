//
//  ExtraFields.swift
//  OpenAI
//

import Foundation

extension Decoder {
    /// Decodes top-level properties not represented by `Keys`, or returns `nil` if there are none.
    func decodeExtraFields<Keys: CodingKey>(excluding keys: Keys.Type) throws -> JSONObject? {
        let container = try container(keyedBy: AnyCodingKey.self)
        var extraFields: JSONObject = [:]
        for key in container.allKeys where Keys(stringValue: key.stringValue) == nil {
            extraFields[key.stringValue] = try container.decode(AnyJSONDocument.self, forKey: key)
        }
        return extraFields.isEmpty ? nil : extraFields
    }
}

extension Dictionary where Key == String, Value == AnyJSONDocument {
    /// Decodes the value for `key` as `T`, or returns `nil` when there is no such key.
    func decodeValue<T: Decodable>(forKey key: String, as type: T.Type) throws -> T? {
        guard let value = self[key] else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }
}
