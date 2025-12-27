import Foundation
import SwiftUI
import Combine

// MARK: - Infinity Game Logic (ViewModel principal)

class InfinityGameLogic: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSubMode: InfinitySubMode? = nil
    @Published var showingModeSelector = true
    
    // Infinite Tic-Tac-Toe
    @Published var infiniteBoard = InfiniteBoardState()
    @Published var infiniteGameMode: InfiniteGameMode = .vsAI
    @Published var infiniteCurrentPlayer: Player = .player1
    @Published var infiniteIsGameOver = false
    @Published var infiniteWinner: Player = .none
    @Published var aiLevel: AILevel = .medium
    @Published var aiConsecutiveWins = 0
    @Published var playerConsecutiveWins = 0
    
    // Three-in-One
    @Published var threeInOneState = ThreeInOneState()
    @Published var threeInOneWinner: Player = .none
    @Published var threeInOneGameOver = false
    
    // Memory Flash
    @Published var memoryFlashState = MemoryFlashState()
    @Published var memoryFlashMessage = ""
    
    private var timerCancellable: AnyCancellable?
    
    // MARK: - Navigation
    
    func selectSubMode(_ mode: InfinitySubMode) {
        currentSubMode = mode
        showingModeSelector = false
        
        // Inicializar el modo seleccionado
        switch mode {
        case .infiniteTicTacToe:
            resetInfiniteTicTacToe()
        case .threeInOne:
            resetThreeInOne()
        }
    }
    
    func backToModeSelector() {
        showingModeSelector = true
        currentSubMode = nil
        
        // Limpiar estados
        timerCancellable?.cancel()
    }
    
    // MARK: - INFINITE TIC-TAC-TOE Logic
    
    func resetInfiniteTicTacToe() {
        infiniteBoard.reset()
        infiniteCurrentPlayer = .player1
        infiniteIsGameOver = false
        infiniteWinner = .none
    }
    
    func makeInfiniteMove(at position: GridPosition) {
        guard !infiniteIsGameOver else { return }
        guard infiniteBoard.isEmpty(at: position) else { return }
        
        // Hacer movimiento
        if infiniteBoard.makeMove(at: position, player: infiniteCurrentPlayer) {
            
            // Verificar ganador
            if let winner = InfiniteWinChecker.checkWinner(board: infiniteBoard, lastMove: position) {
                endInfiniteGame(winner: winner)
                return
            }
            
            // Cambiar turno
            infiniteCurrentPlayer = infiniteCurrentPlayer.opponent
            
            // Si es vs IA y es turno de la IA
            if infiniteGameMode == .vsAI && infiniteCurrentPlayer == .player2 {
                makeInfiniteAIMove()
            }
        }
    }
    
    private func makeInfiniteAIMove() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self, !self.infiniteIsGameOver else { return }
            
            let move = self.getBestInfiniteMove()
            if let move = move {
                if self.infiniteBoard.makeMove(at: move, player: .player2) {
                    
                    // Verificar ganador
                    if let winner = InfiniteWinChecker.checkWinner(board: self.infiniteBoard, lastMove: move) {
                        self.endInfiniteGame(winner: winner)
                        return
                    }
                    
                    // Cambiar turno
                    self.infiniteCurrentPlayer = .player1
                }
            }
        }
    }
    
    private func getBestInfiniteMove() -> GridPosition? {
        let availableMoves = infiniteBoard.getAvailableMoves()
        guard !availableMoves.isEmpty else { return nil }
        
        // Limitar el área de búsqueda a movimientos cerca de piezas existentes
        let relevantMoves = getRelevantMoves()
        let movesToConsider = relevantMoves.isEmpty ? availableMoves : relevantMoves
        
        var bestMove: GridPosition?
        var bestScore = Int.min
        
        // Limitar búsqueda según dificultad
        let movesToEvaluate = Array(movesToConsider.prefix(min(movesToConsider.count, 20)))
        
        for move in movesToEvaluate {
            let boardCopy = infiniteBoard.getCopy()
            let _ = boardCopy.makeMove(at: move, player: .player2)
            
            let score = infiniteMinimax(board: boardCopy, depth: 0, alpha: Int.min, beta: Int.max, isMaximizing: false, maxDepth: aiLevel.searchDepth)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove ?? movesToConsider.randomElement()
    }
    
    private func getRelevantMoves() -> [GridPosition] {
        var relevant = Set<GridPosition>()
        
        // Buscar todas las piezas en el tablero
        for row in infiniteBoard.minRow...infiniteBoard.maxRow {
            for col in infiniteBoard.minCol...infiniteBoard.maxCol {
                let pos = GridPosition(row: row, col: col)
                if infiniteBoard[pos] != .none {
                    // Agregar posiciones adyacentes
                    for dRow in -1...1 {
                        for dCol in -1...1 {
                            let adjacent = GridPosition(row: pos.row + dRow, col: pos.col + dCol)
                            if infiniteBoard.isEmpty(at: adjacent) {
                                relevant.insert(adjacent)
                            }
                        }
                    }
                }
            }
        }
        
        return Array(relevant)
    }
    
    private func infiniteMinimax(board: InfiniteBoardState, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool, maxDepth: Int) -> Int {
        
        // Verificar si alcanzamos profundidad máxima
        if depth >= maxDepth {
            return evaluateInfiniteBoard(board: board)
        }
        
        // Obtener movimientos relevantes
        let moves = getRelevantMoves(for: board)
        
        if isMaximizing {
            var maxEval = Int.min
            var currentAlpha = alpha
            
            for move in moves.prefix(10) {
                let boardCopy = board.getCopy()
                let _ = boardCopy.makeMove(at: move, player: .player2)
                
                // Verificar victoria inmediata
                if let winner = InfiniteWinChecker.checkWinner(board: boardCopy, lastMove: move) {
                    return winner == .player2 ? 1000 - depth : -1000 + depth
                }
                
                let eval = infiniteMinimax(board: boardCopy, depth: depth + 1, alpha: currentAlpha, beta: beta, isMaximizing: false, maxDepth: maxDepth)
                maxEval = max(maxEval, eval)
                currentAlpha = max(currentAlpha, eval)
                
                if beta <= currentAlpha {
                    break // Poda beta
                }
            }
            return maxEval
            
        } else {
            var minEval = Int.max
            var currentBeta = beta
            
            for move in moves.prefix(10) {
                let boardCopy = board.getCopy()
                let _ = boardCopy.makeMove(at: move, player: .player1)
                
                // Verificar victoria inmediata
                if let winner = InfiniteWinChecker.checkWinner(board: boardCopy, lastMove: move) {
                    return winner == .player1 ? -1000 + depth : 1000 - depth
                }
                
                let eval = infiniteMinimax(board: boardCopy, depth: depth + 1, alpha: alpha, beta: currentBeta, isMaximizing: true, maxDepth: maxDepth)
                minEval = min(minEval, eval)
                currentBeta = min(currentBeta, eval)
                
                if currentBeta <= alpha {
                    break // Poda alfa
                }
            }
            return minEval
        }
    }
    
    private func getRelevantMoves(for board: InfiniteBoardState) -> [GridPosition] {
        var relevant = Set<GridPosition>()
        
        for row in board.minRow...board.maxRow {
            for col in board.minCol...board.maxCol {
                let pos = GridPosition(row: row, col: col)
                if board[pos] != .none {
                    for dRow in -1...1 {
                        for dCol in -1...1 {
                            let adjacent = GridPosition(row: pos.row + dRow, col: pos.col + dCol)
                            if board.isEmpty(at: adjacent) {
                                relevant.insert(adjacent)
                            }
                        }
                    }
                }
            }
        }
        
        return relevant.isEmpty ? board.getAvailableMoves() : Array(relevant)
    }
    
    private func evaluateInfiniteBoard(board: InfiniteBoardState) -> Int {
        // Evaluación heurística simple
        return 0
    }
    
    private func endInfiniteGame(winner: Player) {
        infiniteIsGameOver = true
        infiniteWinner = winner
        
        // Ajustar IA adaptativa
        adaptAI(winner: winner)
    }
    
    private func adaptAI(winner: Player) {
        if winner == .player1 {
            // Jugador ganó
            playerConsecutiveWins += 1
            aiConsecutiveWins = 0
            
            // Si el jugador gana 2 veces seguidas, aumentar dificultad
            if playerConsecutiveWins >= 2 && aiLevel.rawValue < 4 {
                aiLevel = AILevel(rawValue: aiLevel.rawValue + 1) ?? .expert
                playerConsecutiveWins = 0
            }
            
        } else if winner == .player2 {
            // IA ganó
            aiConsecutiveWins += 1
            playerConsecutiveWins = 0
            
            // Si la IA gana 3 veces seguidas, bajar dificultad
            if aiConsecutiveWins >= 3 && aiLevel.rawValue > 1 {
                aiLevel = AILevel(rawValue: aiLevel.rawValue - 1) ?? .easy
                aiConsecutiveWins = 0
            }
        } else {
            // Empate - resetear contadores
            playerConsecutiveWins = 0
            aiConsecutiveWins = 0
        }
    }
    
    // MARK: - THREE-IN-ONE Logic
    
    func resetThreeInOne() {
        threeInOneState.reset()
        threeInOneWinner = .none
        threeInOneGameOver = false
        timerCancellable?.cancel()
    }
    
    func selectThreeInOneVariant(_ variant: ThreeInOneVariant) {
        threeInOneState.variant = variant
        threeInOneState.reset()
        threeInOneGameOver = false
        threeInOneWinner = .none
        
        if variant == .timed {
            startTimedGame()
        }
    }
    
    func selectPlayerCount(_ count: Int) {
        threeInOneState.playerCount = count
    }
    
    func makeThreeInOneMove(row: Int, col: Int) {
        guard !threeInOneGameOver else { return }
        guard threeInOneState.board.isEmpty(row: row, col: col) else { return }
        
        if threeInOneState.board.makeMove(row: row, col: col, player: threeInOneState.currentPlayer) {
            
            // Verificar ganador
            if let winner = checkThreeInOneWinner() {
                threeInOneWinner = winner
                threeInOneGameOver = true
                timerCancellable?.cancel()
                return
            }
            
            // Verificar empate
            if threeInOneState.board.isFull() {
                threeInOneWinner = .none
                threeInOneGameOver = true
                timerCancellable?.cancel()
                return
            }
            
            // Cambiar turno
            threeInOneState.currentPlayer = threeInOneState.currentPlayer.opponent
            
            // Resetear timer si es modo cronometrado
            if threeInOneState.variant == .timed {
                threeInOneState.timeRemaining = 30
            }
        }
    }
    
    private func startTimedGame() {
        threeInOneState.isGameActive = true
        threeInOneState.timeRemaining = 30
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.threeInOneState.timeRemaining > 0 {
                    self.threeInOneState.timeRemaining -= 1
                } else {
                    // Tiempo agotado - cambiar turno
                    self.threeInOneState.currentPlayer = self.threeInOneState.currentPlayer.opponent
                    self.threeInOneState.timeRemaining = 30
                }
            }
    }
    
    private func checkThreeInOneWinner() -> Player? {
        let board = threeInOneState.board
        
        // Verificar filas
        for row in 0..<3 {
            if board[row, 0] != .empty &&
               board[row, 0] == board[row, 1] &&
               board[row, 1] == board[row, 2] {
                return board[row, 0].player
            }
        }
        
        // Verificar columnas
        for col in 0..<3 {
            if board[0, col] != .empty &&
               board[0, col] == board[1, col] &&
               board[1, col] == board[2, col] {
                return board[0, col].player
            }
        }
        
        // Verificar diagonales
        if board[0, 0] != .empty &&
           board[0, 0] == board[1, 1] &&
           board[1, 1] == board[2, 2] {
            return board[0, 0].player
        }
        
        if board[0, 2] != .empty &&
           board[0, 2] == board[1, 1] &&
           board[1, 1] == board[2, 0] {
            return board[0, 2].player
        }
        
        return nil
    }
    
    // MARK: - MEMORY FLASH Logic
    
    func resetMemoryFlash() {
        memoryFlashState.reset()
        memoryFlashMessage = "Nivel 1 - ¡Prepárate!"
    }
    
    func startMemoryFlashLevel() {
        memoryFlashState.gameActive = true
        memoryFlashState.generateSequence()
        showMemorySequence()
    }
    
    private func showMemorySequence() {
        memoryFlashState.isShowingSequence = true
        memoryFlashState.isWaitingForInput = false
        
        var currentIndex = 0
        let sequence = memoryFlashState.sequence
        let flashSpeed = memoryFlashState.flashSpeed
        
        Timer.scheduledTimer(withTimeInterval: flashSpeed, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if currentIndex < sequence.count {
                // Flash actual se maneja en la vista
                currentIndex += 1
            } else {
                timer.invalidate()
                self.memoryFlashState.isShowingSequence = false
                self.memoryFlashState.isWaitingForInput = true
                self.memoryFlashMessage = "¡Tu turno! Repite la secuencia"
            }
        }
    }
    
    func handleMemoryFlashTap(_ index: Int) {
        guard memoryFlashState.isWaitingForInput else { return }
        
        memoryFlashState.userSequence.append(index)
        
        // Verificar si la secuencia está completa
        if memoryFlashState.userSequence.count == memoryFlashState.sequence.count {
            checkMemoryFlashResult()
        }
    }
    
    private func checkMemoryFlashResult() {
        if memoryFlashState.checkUserInput() {
            // ¡Correcto!
            if memoryFlashState.currentLevel == 9 {
                // ¡Ganó todos los niveles!
                memoryFlashMessage = "🎉 ¡Completaste todos los niveles! 🎉"
                memoryFlashState.gameActive = false
            } else {
                memoryFlashState.levelCompleted = true
                memoryFlashMessage = "✅ ¡Nivel \(memoryFlashState.currentLevel) completado!"
                
                // Avanzar al siguiente nivel después de 2 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.memoryFlashState.nextLevel()
                    self?.memoryFlashMessage = "Nivel \(self?.memoryFlashState.currentLevel ?? 1) - ¡Listo!"
                    self?.memoryFlashState.levelCompleted = false
                    
                    // Auto-iniciar siguiente nivel
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        self?.startMemoryFlashLevel()
                    }
                }
            }
        } else {
            // Incorrecto - game over
            memoryFlashMessage = "❌ ¡Fallaste! Alcanzaste nivel \(memoryFlashState.currentLevel)"
            memoryFlashState.gameActive = false
        }
    }
}
