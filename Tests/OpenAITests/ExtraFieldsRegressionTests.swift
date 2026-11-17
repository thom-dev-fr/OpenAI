import Foundation
import XCTest
import OpenAI

final class ExtraFieldsRegressionTests: XCTestCase {
    func testEquivalentResponsesCompareEqual() throws {
        let data = Data(#"{"id":"1","object":"chat.completion","created":0,"model":"qwen3","choices":[],"timings":{"prompt_n":1}}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(ChatResult.self, from: data), try JSONDecoder().decode(ChatResult.self, from: data))
        XCTAssertEqual(try JSONDecoder().decode(ChatStreamResult.self, from: data), try JSONDecoder().decode(ChatStreamResult.self, from: data))
    }

    func testLargeNumbersSurviveResponseDecodingAndTypedAccess() throws {
        for number in ["1e200", "-1e200", "1e-200"] {
            let data = Data("{\"id\":\"1\",\"object\":\"chat.completion\",\"created\":0,\"model\":\"qwen3\",\"choices\":[],\"provider_value\":\(number)}".utf8)
            let result = try JSONDecoder().decode(ChatResult.self, from: data)
            let stream = try JSONDecoder().decode(ChatStreamResult.self, from: data)
            XCTAssertEqual(try result.extraField("provider_value", as: Double.self), Double(number))
            XCTAssertEqual(try stream.extraField("provider_value", as: Double.self), Double(number))
        }
    }

    func testResponseRoundTripsOmitExtraFieldsButDictionaryCanBeSavedSeparately() throws {
        let data = Data(#"{"id":"1","object":"chat.completion","created":0,"model":"local-model","choices":[],"provider_option":null}"#.utf8)
        let chat = try JSONDecoder().decode(ChatResult.self, from: data)
        let stream = try JSONDecoder().decode(ChatStreamResult.self, from: data)
        XCTAssertEqual(chat.extraFields?["provider_option"], .null)
        XCTAssertEqual(stream.extraFields?["provider_option"], .null)
        XCTAssertNil(try JSONDecoder().decode(ChatResult.self, from: JSONEncoder().encode(chat)).extraFields)
        XCTAssertNil(try JSONDecoder().decode(ChatStreamResult.self, from: JSONEncoder().encode(stream)).extraFields)

        let extras = try XCTUnwrap(chat.extraFields)
        XCTAssertEqual(try JSONDecoder().decode(JSONObject.self, from: JSONEncoder().encode(extras)), extras)
    }
}
