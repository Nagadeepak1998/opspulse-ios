import Foundation

public protocol APITokenProvider: Sendable {
    func token() async throws -> String?
}

public struct StaticTokenProvider: APITokenProvider {
    private let value: String?

    public init(_ value: String?) {
        self.value = value
    }

    public func token() async throws -> String? {
        value
    }
}

public struct HealthResponse: Codable, Equatable, Sendable {
    public var status: String
    public var version: String
    public var generatedAt: Date

    public init(status: String, version: String, generatedAt: Date) {
        self.status = status
        self.version = version
        self.generatedAt = generatedAt
    }
}

public enum OpsAPIError: Error, Equatable, LocalizedError, Sendable {
    case invalidBaseURL
    case invalidResponse
    case timeout
    case unauthorized
    case server(statusCode: Int, body: String)
    case decoding(String)
    case connectivity(String)

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL: "The live API base URL is invalid."
        case .invalidResponse: "The server returned an invalid response."
        case .timeout: "The request timed out."
        case .unauthorized: "Authentication failed. Check the stored API token."
        case let .server(statusCode, body): "Server error \(statusCode): \(body)"
        case let .decoding(message): "Could not decode the API response: \(message)"
        case let .connectivity(message): "Connection failed: \(message)"
        }
    }
}

public protocol OpsAPIClient: Sendable {
    func health() async throws -> HealthResponse
    func services() async throws -> [OpsService]
    func service(id: String) async throws -> OpsService
    func incidents() async throws -> [Incident]
    func incident(id: String) async throws -> Incident
    func acknowledgeIncident(id: String) async throws -> Incident
    func addTimeline(id: String, note: String) async throws -> Incident
    func transitionIncident(id: String, to status: IncidentStatus) async throws -> Incident
}

public final class HTTPOpsAPI: OpsAPIClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: APITokenProvider
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(baseURL: URL, session: URLSession = .shared, tokenProvider: APITokenProvider = StaticTokenProvider(nil)) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    public func health() async throws -> HealthResponse {
        try await send(path: "/health")
    }

    public func services() async throws -> [OpsService] {
        try await send(path: "/api/v1/services")
    }

    public func service(id: String) async throws -> OpsService {
        try await send(path: "/api/v1/services/\(id)")
    }

    public func incidents() async throws -> [Incident] {
        try await send(path: "/api/v1/incidents")
    }

    public func incident(id: String) async throws -> Incident {
        try await send(path: "/api/v1/incidents/\(id)")
    }

    public func acknowledgeIncident(id: String) async throws -> Incident {
        try await send(path: "/api/v1/incidents/\(id)/acknowledge", method: "POST", body: EmptyBody())
    }

    public func addTimeline(id: String, note: String) async throws -> Incident {
        try await send(path: "/api/v1/incidents/\(id)/timeline", method: "POST", body: TimelineRequest(note: note))
    }

    public func transitionIncident(id: String, to status: IncidentStatus) async throws -> Incident {
        try await send(path: "/api/v1/incidents/\(id)/transition", method: "POST", body: TransitionRequest(status: status))
    }

    private func send<Response: Decodable>(path: String, method: String = "GET") async throws -> Response {
        try await send(path: path, method: method, body: Optional<EmptyBody>.none)
    }

    private func send<Response: Decodable, Body: Encodable>(path: String, method: String = "GET", body: Body?) async throws -> Response {
        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = try await tokenProvider.token(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw OpsAPIError.invalidResponse }
            switch httpResponse.statusCode {
            case 200..<300:
                do {
                    return try decoder.decode(Response.self, from: data)
                } catch {
                    throw OpsAPIError.decoding(error.localizedDescription)
                }
            case 401, 403:
                throw OpsAPIError.unauthorized
            default:
                throw OpsAPIError.server(statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8) ?? "")
            }
        } catch let error as OpsAPIError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw OpsAPIError.timeout
        } catch {
            throw OpsAPIError.connectivity(error.localizedDescription)
        }
    }

    private struct EmptyBody: Codable, Sendable {}

    private struct TimelineRequest: Codable, Sendable {
        var note: String
    }

    private struct TransitionRequest: Codable, Sendable {
        var status: IncidentStatus
    }
}
