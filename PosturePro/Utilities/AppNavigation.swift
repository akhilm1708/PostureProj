import Foundation

enum AppView: String, Identifiable {
    case main
    case recording
    case history
    
    var id: String { rawValue }
}

