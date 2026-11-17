import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import OpenAI

final class ExtraBodyRequestTests: XCTestCase {
    private let session = URLSessionMock()
    private let streamingFactory = MockStreamingSessionFactory()
    private lazy var client = OpenAI(
        configuration: .init(token: "test-token"),
        session: session,
        streamingSessionFactory: streamingFactory,
        executionSerializer: NoDispatchExecutionSerializer()
    )

    private var extras: JSONObject {
        [
            "chat_template_kwargs": AnyJSONDocument(["enable_thinking": false]),
            "top_k": AnyJSONDocument(40),
            "metadata": AnyJSONDocument(["replacement": "value"]),
            "temperature": .null
        ]
    }

    func testChatAsyncSendsExtraBody() async throws {
        session.dataTask = try .successfulJson(with: ChatResult.mock)
        let query = ChatQuery(messages: [], model: "local-model", metadata: ["original": "value"], temperature: 0.5, extraBody: extras)
        _ = try await client.chats(query: query)
        let request = try XCTUnwrap(session.dataAsyncCalls.last?.request)
        try assertBody(request, path: "/v1/chat/completions", stream: false)
    }

    func testChatCallbackPreservesExtraBodyWhenDisablingStreaming() throws {
        session.dataTask = try .successfulJson(with: ChatResult.mock)
        let query = ChatQuery(messages: [], model: "local-model", metadata: ["original": "value"], temperature: 0.5, stream: true, extraBody: extras)
        let completed = expectation(description: "Chat completed")
        _ = client.chats(query: query) { result in
            if case .failure(let error) = result { XCTFail("Unexpected error: \(error)") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 1)
        let request = try XCTUnwrap(session.dataTaskWithCompletionCalls.last?.request)
        try assertBody(request, path: "/v1/chat/completions", stream: false)
    }

    func testChatStreamingPreservesExtraBodyWhenEnablingStreaming() throws {
        let streamingSession = streamingFactory.urlSessionFactory.urlSession
        streamingSession.dataTask = DataTaskMock()
        let query = ChatQuery(messages: [], model: "local-model", metadata: ["original": "value"], temperature: 0.5, extraBody: extras)
        let task = client.chatsStream(query: query, onResult: { _ in }, completion: { error in
            if let error { XCTFail("Unexpected error: \(error)") }
        })
        defer { task.cancelRequest() }
        let request = try XCTUnwrap(streamingSession.dataTaskCalls.last?.request)
        try assertBody(request, path: "/v1/chat/completions", stream: true)
    }

    func testResponsesAsyncSendsExtraBody() async throws {
        session.dataTask = try .successfulJson(with: ResponseObject.makeMock())
        let query = CreateModelResponseQuery(input: .textInput("Hi"), model: "local-model", metadata: .init(additionalProperties: ["original": "value"]), stream: false, temperature: 0.5, extraBody: extras)
        _ = try await client.responses.createResponse(query: query)
        let request = try XCTUnwrap(session.dataAsyncCalls.last?.request)
        try assertBody(request, path: "/v1/responses", stream: false)
    }

    func testResponsesStreamingSendsExtraBody() throws {
        let streamingSession = streamingFactory.urlSessionFactory.urlSession
        streamingSession.dataTask = DataTaskMock()
        let query = CreateModelResponseQuery(input: .textInput("Hi"), model: "local-model", metadata: .init(additionalProperties: ["original": "value"]), stream: true, temperature: 0.5, extraBody: extras)
        let task = client.responses.createResponseStreaming(query: query, onResult: { _ in }, completion: { error in
            if let error { XCTFail("Unexpected error: \(error)") }
        })
        defer { task.cancelRequest() }
        let request = try XCTUnwrap(streamingSession.dataTaskCalls.last?.request)
        try assertBody(request, path: "/v1/responses", stream: true)
    }

    private func assertBody(_ request: URLRequest, path: String, stream: Bool, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(request.httpMethod, "POST", file: file, line: line)
        XCTAssertEqual(request.url?.path, path, file: file, line: line)
        let data = try XCTUnwrap(request.httpBody, file: file, line: line)
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], file: file, line: line)
        XCTAssertEqual(body["model"] as? String, "local-model", file: file, line: line)
        XCTAssertEqual(body["stream"] as? Bool, stream, file: file, line: line)
        XCTAssertEqual(body["chat_template_kwargs"] as? [String: Bool], ["enable_thinking": false], file: file, line: line)
        XCTAssertEqual(body["top_k"] as? Int, 40, file: file, line: line)
        XCTAssertTrue(body["temperature"] is NSNull, file: file, line: line)
        XCTAssertEqual(body["metadata"] as? [String: String], ["replacement": "value"], file: file, line: line)
        XCTAssertNil(body["extraBody"], file: file, line: line)
        XCTAssertNil(body["extra_body"], file: file, line: line)
    }
}
