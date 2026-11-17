import Foundation
import XCTest
import OpenAI

final class ExtraBodyRegressionTests: XCTestCase {
    func testEquivalentQueriesCompareEqual() throws {
        let a = ChatQuery(messages: [], model: "qwen3", extraBody: ["min_p": AnyJSONDocument(0.05)])
        let b = ChatQuery(messages: [], model: "qwen3", extraBody: ["min_p": AnyJSONDocument(0.05)])
        XCTAssertEqual(a, b)
    }

    func testOriginalInitializerReferencesRemainAvailable() {
        _ = ChatQuery.init(messages:model:modalities:audioOptions:reasoningEffort:frequencyPenalty:logitBias:logprobs:maxCompletionTokens:metadata:n:parallelToolCalls:prediction:presencePenalty:responseFormat:seed:serviceTier:stop:store:temperature:toolChoice:tools:topLogprobs:topP:user:webSearchOptions:stream:streamOptions:)
        _ = CreateModelResponseQuery.init(input:model:include:background:contextManagement:instructions:maxOutputTokens:metadata:parallelToolCalls:previousResponseId:prompt:promptCacheKey:reasoning:serviceTier:store:stream:temperature:text:toolChoice:tools:topP:truncation:user:)
    }

    func testQueryRoundTripsDoNotPreserveExtraBody() throws {
        let chat = ChatQuery(messages: [], model: "local-model", extraBody: ["provider_option": .null])
        let responses = CreateModelResponseQuery(input: .textInput("Hi"), extraBody: ["provider_option": .null])
        XCTAssertNil(try JSONDecoder().decode(ChatQuery.self, from: JSONEncoder().encode(chat)).extraBody)
        XCTAssertNil(try JSONDecoder().decode(CreateModelResponseQuery.self, from: JSONEncoder().encode(responses)).extraBody)
    }
}
