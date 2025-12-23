import Foundation

class StorageService {
    static let shared = StorageService()

    private let fileManager = FileManager.default
    private var appSupportURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }

    private var sessionsDirectory: URL? {
        guard let appSupport = appSupportURL else { return nil }
        let sessionsPath = appSupport.appendingPathComponent("PostureApp/sessions")
        try? fileManager.createDirectory(at: sessionsPath, withIntermediateDirectories: true)
        return sessionsPath
    }

    private var userDirectory: URL? {
        guard let appSupport = appSupportURL else { return nil }
        let userPath = appSupport.appendingPathComponent("PostureApp/user")
        try? fileManager.createDirectory(at: userPath, withIntermediateDirectories: true)
        return userPath
    }

    func getSessionVideoPath(for sessionId: String) -> URL? {
        let fileName = "session_\(sessionId).mp4"
        return sessionsDirectory?.appendingPathComponent(fileName)
    }

    func getSessionMetadataPath(for sessionId: String) -> URL? {
        let fileName = "session_\(sessionId).json"
        return sessionsDirectory?.appendingPathComponent(fileName)
    }

    func saveSession(_ session: SessionModel) throws {
        guard let metadataPath = getSessionMetadataPath(for: session.id) else {
            throw StorageError.noValidPath
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: metadataPath)
    }

    func loadSession(withId sessionId: String) throws -> SessionModel {
        guard let metadataPath = getSessionMetadataPath(for: sessionId) else {
            throw StorageError.noValidPath
        }

        let data = try Data(contentsOf: metadataPath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SessionModel.self, from: data)
    }

    func loadAllSessions() -> [SessionModel] {
        guard let sessionsDir = sessionsDirectory else { return [] }

        do {
            let files = try fileManager.contentsOfDirectory(at: sessionsDir, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }

            var sessions: [SessionModel] = []
            for jsonFile in jsonFiles {
                do {
                    let data = try Data(contentsOf: jsonFile)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let session = try decoder.decode(SessionModel.self, from: data)
                    sessions.append(session)
                } catch {
                    print("Error loading session: \(error)")
                }
            }

            return sessions.sorted { $0.startTime > $1.startTime }
        } catch {
            print("Error reading sessions directory: \(error)")
            return []
        }
    }

    func deleteSession(withId sessionId: String) throws {
        guard let videoPath = getSessionVideoPath(for: sessionId),
              let metadataPath = getSessionMetadataPath(for: sessionId) else {
            throw StorageError.noValidPath
        }

        try? fileManager.removeItem(at: videoPath)
        try? fileManager.removeItem(at: metadataPath)
    }

    func saveUserProfile(_ profile: UserProfile) throws {
        guard let userDir = userDirectory else {
            throw StorageError.noValidPath
        }

        let profilePath = userDir.appendingPathComponent("profile.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        let data = try encoder.encode(profile)
        try data.write(to: profilePath)
    }

    func loadUserProfile() throws -> UserProfile {
        guard let userDir = userDirectory else {
            throw StorageError.noValidPath
        }

        let profilePath = userDir.appendingPathComponent("profile.json")
        let data = try Data(contentsOf: profilePath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserProfile.self, from: data)
    }

    func userProfileExists() -> Bool {
        guard let userDir = userDirectory else { return false }
        let profilePath = userDir.appendingPathComponent("profile.json")
        return fileManager.fileExists(atPath: profilePath.path)
    }
}

enum StorageError: LocalizedError {
    case noValidPath
    case fileNotFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .noValidPath:
            return "No valid path for storage"
        case .fileNotFound:
            return "File not found"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}

