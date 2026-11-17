//
//  CreateModelResponseQueryCodingTests.swift
//  OpenAI
//

// Swift Testing ships with Swift 6 toolchains. The package still supports Swift 5.10, where these tests do not exist.
#if canImport(Testing)
import Testing
@testable import OpenAI
import Foundation

struct CreateModelResponseQueryCodingTests {
    @Test func encodeExtraBodyAsTopLevelFields() throws {
        let query = CreateModelResponseQuery(
            input: .textInput("Hi"),
            model: "qwen3",
            extraBody: [
                "chat_template_kwargs": AnyJSONDocument(["enable_thinking": false]),
                "top_k": AnyJSONDocument(40)
            ]
        )

        let expected: NSDictionary = [
            "input": "Hi",
            "model": "qwen3",
            "chat_template_kwargs": ["enable_thinking": false],
            "top_k": 40
        ]
        #expect(try encoded(query) == expected)
    }

    @Test func extraBodyReplaceStandardFields() throws {
        let query = CreateModelResponseQuery(
            input: .textInput("Hi"),
            model: .gpt4_o,
            temperature: 0.5,
            extraBody: ["temperature": AnyJSONDocument(1)]
        )

        #expect(try encoded(query)["temperature"] as? Int == 1)
    }

    @Test func decodingLeavesExtraBodyNil() throws {
        let data = Data(#"{"input": "Hi", "model": "qwen3", "top_k": 40}"#.utf8)
        let query = try JSONDecoder().decode(CreateModelResponseQuery.self, from: data)
        #expect(query.extraBody == nil)
        #expect(query.model == "qwen3")
    }

    /// `CreateModelResponseQuery.encode(to:)` is hand-written, so a property added to the type but not to it would silently not be sent.
    @Test func encodeEncodesEveryProperty() throws {
        let query = CreateModelResponseQuery(
            input: .textInput("Hi"),
            model: .gpt4_o,
            include: [.fileSearchCall_results],
            background: true,
            contextManagement: [.init(_type: "compaction", compactThreshold: 1000)],
            instructions: "Be concise.",
            maxOutputTokens: 10,
            metadata: .init(additionalProperties: ["key": "value"]),
            parallelToolCalls: true,
            previousResponseId: "resp_1",
            prompt: .init(id: "pmpt_abc123"),
            promptCacheKey: "user-1234",
            reasoning: .init(effort: .low),
            serviceTier: .flexTier,
            store: true,
            stream: false,
            temperature: 0.5,
            text: .init(format: .text, verbosity: .low),
            toolChoice: .ToolChoiceOptions(.auto),
            tools: [.functionTool(FunctionTool(
                type: "function",
                name: "my_function",
                description: "A test function",
                parameters: JSONSchema(fields: [.type(.object)]),
                strict: true
            ))],
            topP: 0.5,
            truncation: "auto",
            user: "user"
        )

        let properties = Mirror(reflecting: query).children.filter { $0.label != "extraBody" }
        // A property left `nil` here isn't encoded either way, so the count below couldn't tell whether encode(to:) handles it.
        let nilProperties = properties.filter { property in
            let mirror = Mirror(reflecting: property.value)
            return mirror.displayStyle == .optional && mirror.children.isEmpty
        }
        #expect(nilProperties.map(\.label) == [], "Set every property in this test")
        #expect(try encoded(query).count == properties.count)
    }

    private func encoded(_ query: CreateModelResponseQuery) throws -> NSDictionary {
        let data = try JSONEncoder().encode(query)
        return NSDictionary(dictionary: try JSONSerialization.jsonObject(with: data) as! [String: Any])
    }
}
#endif
