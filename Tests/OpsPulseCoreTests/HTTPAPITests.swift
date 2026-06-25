import Foundation
import Testing
@testable import OpsPulseCore

@Suite("HTTP API", .serialized)
struct HTTPAPITests {
    init() {
        MockURLProtocol.handler = nil
    }

    @Test func healthSuccessDecodesResponseAndAddsAuthorizationHeader() async throws {
        let api = makeAPI(token: "secret-token")
        MockURLProtocol.handler = { request in
            #expect(request.url?.path == "/health")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
            let body = #"{"status":"ok","version":"demo","generatedAt":"2025-01-01T00:00:00Z"}"#.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }

        let health = try await api.health()

        #expect(health.status == "ok")
        #expect(health.version == "demo")
    }

    @Test func unauthorizedMapsToTypedError() async {
        let api = makeAPI(token: nil)
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await api.services()
            #expect(Bool(false), "Expected unauthorized error")
        } catch {
            #expect(error as? OpsAPIError == .unauthorized)
        }
    }

    @Test func decodingFailureMapsToTypedError() async {
        let api = makeAPI(token: nil)
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("not-json".utf8))
        }

        do {
            _ = try await api.health()
            #expect(Bool(false), "Expected decoding error")
        } catch let error as OpsAPIError {
            guard case .decoding = error else {
                #expect(Bool(false), "Expected decoding error, got \(error)")
                return
            }
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }

    private func makeAPI(token: String?) -> HTTPOpsAPI {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return HTTPOpsAPI(
            baseURL: URL(string: "https://ops.example")!,
            session: session,
            tokenProvider: StaticTokenProvider(token)
        )
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
