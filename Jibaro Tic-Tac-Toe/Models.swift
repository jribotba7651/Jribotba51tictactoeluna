import Foundation
import SwiftUI

// MARK: - Enumeraciones del juego
enum GameMode: CaseIterable {
    case lunaMode
    case unbeatableMode

    var title: String {
        switch self {
        case .lunaMode: return "Luna Mode"
        case .unbeatableMode: return "Unbeatable Mode"
        }
    }

    var subtitle: String {
        switch self {
        case .lunaMode: return "Tú y Luna vs la diversión"
        case .unbeatableMode: return "Desafía a la IA imposible"
        }
    }

    var icon: String {
        switch self {
        case .lunaMode: return "🌙"
        case .unbeatableMode: return "🤖"
        }
    }

    var features: [String] {
        switch self {
        case .lunaMode:
            return ["Luna 🌙 vs Papá ⭐", "Efectos mágicos ✨", "Mensajes en español 💕"]
        case .unbeatableMode:
            return ["IA imbatible", "Algoritmo Minimax", "¡Atrévete a intentarlo!"]
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .lunaMode:
            return [Color.pink.opacity(0.8), Color.orange.opacity(0.6)]
        case .unbeatableMode:
            return [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]
        }
    }
}

enum Player: String, CaseIterable {
    case player1 = "player1"
    case player2 = "player2"
    case none = "none"

    var opponent: Player {
        switch self {
        case .player1: return .player2
        case .player2: return .player1
        case .none: return .none
        }
    }
}

enum GameState {
    case menu
    case playing
    case gameOver(winner: Player)
    case settings
}

enum CellState {
    case empty
    case player1
    case player2

    var player: Player {
        switch self {
        case .empty: return .none
        case .player1: return .player1
        case .player2: return .player2
        }
    }
}

// MARK: - Modelo de configuración de jugador
struct PlayerConfig {
    var name: String
    var emoji: String

    static let defaultPlayer1 = PlayerConfig(name: "Luna", emoji: "🌙")
    static let defaultPlayer2 = PlayerConfig(name: "Papá", emoji: "⭐")
}

// MARK: - Modelo de puntuaciones
struct GameScores {
    var player1Wins: Int = 0
    var player2Wins: Int = 0
    var draws: Int = 0

    mutating func reset() {
        player1Wins = 0
        player2Wins = 0
        draws = 0
    }

    mutating func addWin(for player: Player) {
        switch player {
        case .player1:
            player1Wins += 1
        case .player2:
            player2Wins += 1
        case .none:
            draws += 1
        }
    }
}

// MARK: - Estado del tablero de juego
struct GameBoard {
    private var board: [[CellState]] = Array(repeating: Array(repeating: .empty, count: 3), count: 3)

    subscript(row: Int, col: Int) -> CellState {
        get {
            guard isValidPosition(row: row, col: col) else { return .empty }
            return board[row][col]
        }
        set {
            guard isValidPosition(row: row, col: col) else { return }
            board[row][col] = newValue
        }
    }

    private func isValidPosition(row: Int, col: Int) -> Bool {
        return row >= 0 && row < 3 && col >= 0 && col < 3
    }

    func isEmpty(row: Int, col: Int) -> Bool {
        return self[row, col] == .empty
    }

    func isFull() -> Bool {
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col] == .empty {
                    return false
                }
            }
        }
        return true
    }

    mutating func makeMove(row: Int, col: Int, player: Player) -> Bool {
        guard isEmpty(row: row, col: col) else { return false }

        switch player {
        case .player1:
            self[row, col] = .player1
        case .player2:
            self[row, col] = .player2
        case .none:
            return false
        }
        return true
    }

    mutating func reset() {
        board = Array(repeating: Array(repeating: .empty, count: 3), count: 3)
    }

    // Para uso del algoritmo Minimax
    func getAvailableMoves() -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col] == .empty {
                    moves.append((row, col))
                }
            }
        }
        return moves
    }

    func getCopy() -> GameBoard {
        var copy = GameBoard()
        copy.board = self.board
        return copy
    }
}

// MARK: - Emojis disponibles para selección
struct EmojiCollection {
    static let availableEmojis = [
        "🌙", "⭐", "❤️", "💙",
        "🔥", "⚡", "🌈", "✨",
        "🦄", "🐱", "🐶", "🦋",
        "🌸", "🍀", "🎈", "🎯"
    ]
}