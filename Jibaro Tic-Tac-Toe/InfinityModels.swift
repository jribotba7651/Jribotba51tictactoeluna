import Foundation
import SwiftUI

// MARK: - Infinity Papá Mode - Sub-Modes
enum InfinitySubMode: String, CaseIterable {
    case infiniteTicTacToe = "Infinite Tic-Tac-Toe"
    case threeInOne = "Three-in-One Puzzle"
    
    var title: String {
        switch self {
        case .infiniteTicTacToe:
            return "Infinite Tic-Tac-Toe"
        case .threeInOne:
            return "Three-in-One Puzzle"
        }
    }
    
    var subtitle: String {
        switch self {
        case .infiniteTicTacToe:
            return "Tablero expandible con IA adaptativa"
        case .threeInOne:
            return "3 variantes para toda la familia"
        }
    }
    
    var icon: String {
        switch self {
        case .infiniteTicTacToe:
            return "grid.circle.fill"
        case .threeInOne:
            return "square.grid.3x3.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .infiniteTicTacToe:
            return "🔲"
        case .threeInOne:
            return "🎯"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .infiniteTicTacToe:
            return [Color.purple.opacity(0.8), Color.indigo.opacity(0.6)]
        case .threeInOne:
            return [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)]
        }
    }
}

// MARK: - Infinite Tic-Tac-Toe Models

/// Posición en el grid expandible
struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
}

/// Dificultad de la IA adaptativa
enum AILevel: Int, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3
    case expert = 4
    
    var title: String {
        switch self {
        case .easy: return "Fácil"
        case .medium: return "Medio"
        case .hard: return "Difícil"
        case .expert: return "Experto"
        }
    }
    
    var searchDepth: Int {
        switch self {
        case .easy: return 2
        case .medium: return 4
        case .hard: return 6
        case .expert: return 8
        }
    }
}

/// Modo de juego para Infinite Tic-Tac-Toe
enum InfiniteGameMode {
    case vsPlayer
    case vsAI
}

/// Estado del tablero infinito
class InfiniteBoardState {
    private var cells: [GridPosition: Player] = [:]
    var minRow: Int = 0
    var maxRow: Int = 4  // Empieza con un grid 5x5
    var minCol: Int = 0
    var maxCol: Int = 4
    
    subscript(position: GridPosition) -> Player {
        get { cells[position] ?? .none }
        set { cells[position] = newValue }
    }
    
    func isEmpty(at position: GridPosition) -> Bool {
        return self[position] == .none
    }
    
    func makeMove(at position: GridPosition, player: Player) -> Bool {
        guard isEmpty(at: position) else { return false }
        self[position] = player
        expandIfNeeded(for: position)
        return true
    }
    
    private func expandIfNeeded(for position: GridPosition) {
        // Expandir el grid si el movimiento está cerca del borde
        if position.row <= minRow + 1 {
            minRow -= 2
        }
        if position.row >= maxRow - 1 {
            maxRow += 2
        }
        if position.col <= minCol + 1 {
            minCol -= 2
        }
        if position.col >= maxCol - 1 {
            maxCol += 2
        }
    }
    
    func getAvailableMoves() -> [GridPosition] {
        var moves: [GridPosition] = []
        for row in minRow...maxRow {
            for col in minCol...maxCol {
                let pos = GridPosition(row: row, col: col)
                if isEmpty(at: pos) {
                    moves.append(pos)
                }
            }
        }
        return moves
    }
    
    func reset() {
        cells.removeAll()
        minRow = 0
        maxRow = 4
        minCol = 0
        maxCol = 4
    }
    
    func getCopy() -> InfiniteBoardState {
        let copy = InfiniteBoardState()
        copy.cells = self.cells
        copy.minRow = self.minRow
        copy.maxRow = self.maxRow
        copy.minCol = self.minCol
        copy.maxCol = self.maxCol
        return copy
    }
}

// MARK: - Three-in-One Models

enum ThreeInOneVariant: String, CaseIterable {
    case classic = "Clásico"
    case timed = "Cronometrado"
    case pattern = "Patrón"
    
    var description: String {
        switch self {
        case .classic:
            return "Tic-Tac-Toe tradicional de 3x3"
        case .timed:
            return "30 segundos por movimiento"
        case .pattern:
            return "Gana creando patrones específicos"
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "square.grid.3x3"
        case .timed: return "timer"
        case .pattern: return "wand.and.stars"
        }
    }
}

struct ThreeInOneState {
    var variant: ThreeInOneVariant = .classic
    var playerCount: Int = 2
    var board: GameBoard = GameBoard()
    var currentPlayer: Player = .player1
    var timeRemaining: Int = 30
    var isGameActive = false

    mutating func reset() {
        board.reset()
        currentPlayer = .player1
        timeRemaining = 30
        isGameActive = false
    }
}

// MARK: - Memory Flash Models

class MemoryFlashState {
    var currentLevel: Int = 1
    var sequence: [Int] = []
    var userSequence: [Int] = []
    var isShowingSequence = false
    var isWaitingForInput = false
    var gameActive = false
    var levelCompleted = false
    
    var sequenceLength: Int {
        return min(4 + currentLevel - 1, 12) // Nivel 1 = 4, Nivel 9 = 12
    }
    
    var flashSpeed: Double {
        return max(1.0 - (Double(currentLevel - 1) * 0.1), 0.3) // Más rápido cada nivel
    }
    
    func generateSequence() {
        sequence = (0..<sequenceLength).map { _ in Int.random(in: 0..<9) }
        userSequence.removeAll()
    }
    
    func checkUserInput() -> Bool {
        return userSequence == sequence
    }
    
    func reset() {
        currentLevel = 1
        sequence.removeAll()
        userSequence.removeAll()
        isShowingSequence = false
        isWaitingForInput = false
        gameActive = false
        levelCompleted = false
    }
    
    func nextLevel() {
        if currentLevel < 9 {
            currentLevel += 1
            levelCompleted = false
        }
    }
}

// MARK: - Win Checker for Infinite Tic-Tac-Toe

struct InfiniteWinChecker {
    /// Verifica si hay un ganador (5 en línea)
    static func checkWinner(board: InfiniteBoardState, lastMove: GridPosition) -> Player? {
        let player = board[lastMove]
        guard player != .none else { return nil }
        
        // Direcciones a verificar: horizontal, vertical, diagonal \, diagonal /
        let directions: [(Int, Int)] = [
            (0, 1),   // Horizontal
            (1, 0),   // Vertical
            (1, 1),   // Diagonal \
            (1, -1)   // Diagonal /
        ]
        
        for (dRow, dCol) in directions {
            var count = 1
            
            // Contar en dirección positiva
            count += countInDirection(board: board, from: lastMove, player: player, dRow: dRow, dCol: dCol)
            
            // Contar en dirección negativa
            count += countInDirection(board: board, from: lastMove, player: player, dRow: -dRow, dCol: -dCol)
            
            if count >= 5 {
                return player
            }
        }
        
        return nil
    }
    
    private static func countInDirection(board: InfiniteBoardState, from position: GridPosition, player: Player, dRow: Int, dCol: Int) -> Int {
        var count = 0
        var currentPos = GridPosition(row: position.row + dRow, col: position.col + dCol)
        
        while board[currentPos] == player {
            count += 1
            currentPos = GridPosition(row: currentPos.row + dRow, col: currentPos.col + dCol)
        }
        
        return count
    }
}
