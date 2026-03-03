// Quiet Hacker - Swift Preview
import Foundation

let maxRetries = 3
let apiBaseURL = "https://api.example.com"

protocol Identifiable {
    var id: UUID { get }
    var name: String { get }
}

enum NetworkError: Error, CustomStringConvertible {
    case timeout
    case notFound
    case serverError(code: Int)
    case unknown(String)

    var description: String {
        switch self {
        case .timeout: return "Request timed out"
        case .notFound: return "Resource not found"
        case .serverError(let code): return "Server error: \(code)"
        case .unknown(let msg): return "Unknown: \(msg)"
        }
    }
}

struct User: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    var isActive: Bool

    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.isActive = true
    }
}

actor DataStore {
    private var users: [UUID: User] = [:]

    func add(_ user: User) {
        users[user.id] = user
    }

    func find(by name: String) -> User? {
        users.values.first { $0.name == name }
    }

    func active() -> [User] {
        users.values.filter(\.isActive).sorted { $0.name < $1.name }
    }

    var count: Int { users.count }
}

func fetchUser(id: UUID) async throws -> User {
    let url = URL(string: "\(apiBaseURL)/users/\(id)")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let http = response as? HTTPURLResponse else {
        throw NetworkError.unknown("Invalid response")
    }

    switch http.statusCode {
    case 200:
        return try JSONDecoder().decode(User.self, from: data)
    case 404:
        throw NetworkError.notFound
    default:
        throw NetworkError.serverError(code: http.statusCode)
    }
}

// Main
let store = DataStore()
let names = ["Neo", "Trinity", "Morpheus"]

for name in names {
    let user = User(name: name, email: "\(name.lowercased())@matrix.io")
    await store.add(user)
}

let activeUsers = await store.active()
for user in activeUsers {
    print("[\(user.id.uuidString.prefix(8))] \(user.name) - \(user.email)")
}
