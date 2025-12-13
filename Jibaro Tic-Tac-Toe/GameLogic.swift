import Foundation
import SwiftUI

// MARK: - Gestor principal de la lógica del juego
class GameLogic: ObservableObject {
    @Published var board = GameBoard()
    @Published var currentPlayer: Player = .player1
    @Published var gameMode: GameMode = .lunaMode
    @Published var gameState: GameState = .menu
    @Published var winner: Player = .none
    @Published var isGameOver = false
    @Published var gameMessage = ""

    private let dataManager = DataManager.shared

    init() {
        updateGameMessage()
    }

    // MARK: - Gestión del estado del juego
    func startNewGame(mode: GameMode) {
        gameMode = mode
        resetGame()
        gameState = .playing
    }

    func resetGame() {
        board.reset()
        currentPlayer = .player1
        winner = .none
        isGameOver = false
        updateGameMessage()
    }

    func backToMenu() {
        gameState = .menu
        resetGame()
    }

    func showSettings() {
        gameState = .settings
    }

    // MARK: - Lógica de movimientos
    func makeMove(row: Int, col: Int) {
        guard !isGameOver && board.isEmpty(row: row, col: col) else { return }

        // Realizar movimiento del jugador actual
        if board.makeMove(row: row, col: col, player: currentPlayer) {

            // Verificar si hay ganador
            if let gameWinner = checkForWinner() {
                endGame(winner: gameWinner)
                return
            }

            // Verificar empate
            if board.isFull() {
                endGame(winner: .none)
                return
            }

            // Cambiar turno
            currentPlayer = currentPlayer.opponent

            // Si es modo imbatible y ahora es turno de la IA
            if gameMode == .unbeatableMode && currentPlayer == .player2 {
                makeAIMove()
            } else {
                updateGameMessage()
            }
        }
    }

    // MARK: - Inteligencia Artificial (Minimax)
    private func makeAIMove() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.isGameOver else { return }

            let move = self.getBestMove()
            if let move = move {
                let _ = self.board.makeMove(row: move.0, col: move.1, player: .player2)

                // Verificar ganador después del movimiento de la IA
                if let winner = self.checkForWinner() {
                    self.endGame(winner: winner)
                    return
                }

                // Verificar empate
                if self.board.isFull() {
                    self.endGame(winner: .none)
                    return
                }

                // Cambiar turno de vuelta al jugador
                self.currentPlayer = .player1
                self.updateGameMessage()
            }
        }
    }

    private func getBestMove() -> (Int, Int)? {
        let availableMoves = board.getAvailableMoves()
        var bestMove: (Int, Int)?
        var bestScore = Int.min

        for move in availableMoves {
            var boardCopy = board.getCopy()
            let _ = boardCopy.makeMove(row: move.0, col: move.1, player: .player2)

            let score = minimax(board: boardCopy, depth: 0, isMaximizing: false)

            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }

        return bestMove
    }

    private func minimax(board: GameBoard, depth: Int, isMaximizing: Bool) -> Int {
        // Verificar estados terminales
        if let winner = checkForWinner(on: board) {
            switch winner {
            case .player2: // IA gana
                return 10 - depth
            case .player1: // Humano gana
                return depth - 10
            case .none: // Empate
                return 0
            }
        }

        if board.isFull() {
            return 0
        }

        if isMaximizing {
            // IA está maximizando
            var maxScore = Int.min
            let moves = board.getAvailableMoves()

            for move in moves {
                var newBoard = board.getCopy()
                let _ = newBoard.makeMove(row: move.0, col: move.1, player: .player2)
                let score = minimax(board: newBoard, depth: depth + 1, isMaximizing: false)
                maxScore = max(score, maxScore)
            }
            return maxScore
        } else {
            // Humano está minimizando
            var minScore = Int.max
            let moves = board.getAvailableMoves()

            for move in moves {
                var newBoard = board.getCopy()
                let _ = newBoard.makeMove(row: move.0, col: move.1, player: .player1)
                let score = minimax(board: newBoard, depth: depth + 1, isMaximizing: true)
                minScore = min(score, minScore)
            }
            return minScore
        }
    }

    // MARK: - Detección de victoria
    func checkForWinner() -> Player? {
        return checkForWinner(on: board)
    }

    private func checkForWinner(on gameBoard: GameBoard) -> Player? {
        // Verificar filas
        for row in 0..<3 {
            if gameBoard[row, 0] != .empty &&
               gameBoard[row, 0] == gameBoard[row, 1] &&
               gameBoard[row, 1] == gameBoard[row, 2] {
                return gameBoard[row, 0].player
            }
        }

        // Verificar columnas
        for col in 0..<3 {
            if gameBoard[0, col] != .empty &&
               gameBoard[0, col] == gameBoard[1, col] &&
               gameBoard[1, col] == gameBoard[2, col] {
                return gameBoard[0, col].player
            }
        }

        // Verificar diagonal principal
        if gameBoard[0, 0] != .empty &&
           gameBoard[0, 0] == gameBoard[1, 1] &&
           gameBoard[1, 1] == gameBoard[2, 2] {
            return gameBoard[0, 0].player
        }

        // Verificar diagonal secundaria
        if gameBoard[0, 2] != .empty &&
           gameBoard[0, 2] == gameBoard[1, 1] &&
           gameBoard[1, 1] == gameBoard[2, 0] {
            return gameBoard[0, 2].player
        }

        return nil
    }

    // MARK: - Finalización del juego
    private func endGame(winner: Player) {
        self.winner = winner
        isGameOver = true

        // Actualizar puntuaciones
        dataManager.addWin(for: winner)

        updateGameMessage()
    }

    // MARK: - Mensajes del juego
    private func updateGameMessage() {
        if isGameOver {
            switch gameMode {
            case .lunaMode:
                switch winner {
                case .player1:
                    gameMessage = "¡\(dataManager.getPlayerName(for: .player1)) ganó! ✨🎉"
                case .player2:
                    gameMessage = "¡\(dataManager.getPlayerName(for: .player2)) ganó! ⭐🎊"
                case .none:
                    gameMessage = "¡Empate! Buen juego 🏆"
                }
            case .unbeatableMode:
                switch winner {
                case .player1:
                    gameMessage = "Congratulations! You won! 🎉"
                case .player2:
                    gameMessage = "AI Wins! Better luck next time 🤖"
                case .none:
                    gameMessage = "It's a draw! Well played 🤝"
                }
            }
        } else {
            switch gameMode {
            case .lunaMode:
                let playerName = dataManager.getPlayerName(for: currentPlayer)
                gameMessage = "Turno de \(playerName) - ¡Buena suerte! 😊"
            case .unbeatableMode:
                if currentPlayer == .player1 {
                    gameMessage = "Your turn - Good luck! 🍀"
                } else {
                    gameMessage = "AI is thinking... 🤖"
                }
            }
        }
    }

    // MARK: - Helpers para la UI
    func getCellEmoji(row: Int, col: Int) -> String {
        switch board[row, col] {
        case .empty:
            return ""
        case .player1:
            if gameMode == .unbeatableMode {
                return "○" // Símbolo para Unbeatable Mode
            } else {
                return dataManager.getPlayerEmoji(for: .player1)
            }
        case .player2:
            if gameMode == .unbeatableMode {
                return "×" // Símbolo para Unbeatable Mode
            } else {
                return dataManager.getPlayerEmoji(for: .player2)
            }
        }
    }

    func getPlayerWins(for player: Player) -> Int {
        switch player {
        case .player1:
            return dataManager.gameScores.player1Wins
        case .player2:
            return dataManager.gameScores.player2Wins
        case .none:
            return dataManager.gameScores.draws
        }
    }
}