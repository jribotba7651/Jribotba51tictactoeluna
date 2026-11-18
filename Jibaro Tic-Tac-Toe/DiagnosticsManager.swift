import SwiftUI
import Combine

class DiagnosticsManager: ObservableObject {
    static let shared = DiagnosticsManager()
    
    @Published var logs: [LogEntry] = []
    @Published var adMobStatus: String = "Unknown"
    @Published var iapStatus: String = "Unknown"
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let message: String
        let type: LogType
        
        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: timestamp)
        }
    }
    
    enum LogType {
        case info
        case warning
        case error
        case success
        
        var color: Color {
            switch self {
            case .info: return .gray
            case .warning: return .orange
            case .error: return .red
            case .success: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .success: return "✅"
            }
        }
    }
    
    private init() {}
    
    func log(_ message: String, type: LogType = .info) {
        DispatchQueue.main.async {
            print("[\(type.icon)] \(message)")
            self.logs.insert(LogEntry(message: message, type: type), at: 0)
            
            // Keep only last 100 logs
            if self.logs.count > 100 {
                self.logs.removeLast()
            }
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}
