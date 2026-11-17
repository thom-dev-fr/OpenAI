import Foundation

extension Encoder {
    /// Encodes `extraBody` as top-level fields, replacing any field already encoded under the same name.
    func encodeExtraBody(_ extraBody: JSONObject?) throws {
        guard let extraBody else {
            return
        }
        var container = container(keyedBy: AnyCodingKey.self)
        for (key, value) in extraBody {
            try container.encode(value, forKey: AnyCodingKey(stringValue: key))
        }
    }
}
