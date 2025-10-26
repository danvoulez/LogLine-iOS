import Foundation

// Produz JSON com chaves ordenadas para HMAC determinístico
enum CanonicalJSON {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let any = try toJSONValue(value)
        let sorted = sortJSON(any)
        return try JSONEncoder().encode(sorted)
    }
    private static func toJSONValue<T: Encodable>(_ v: T) throws -> JSONValue {
        let data = try JSONEncoder().encode(v)
        let any = try JSONDecoder().decode(JSONValue.self, from: data)
        return any
    }
    private static func sortJSON(_ v: JSONValue) -> JSONValue {
        switch v {
        case .object(let dict):
            let sorted = dict.keys.sorted().reduce(into: [String: JSONValue]()) { out, k in
                out[k] = sortJSON(dict[k]!)
            }
            return .object(sorted)
        case .array(let arr):
            return .array(arr.map(sortJSON))
        default:
            return v
        }
    }
}
