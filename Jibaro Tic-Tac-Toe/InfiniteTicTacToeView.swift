import SwiftUI

struct InfiniteTicTacToeView: View {
    @ObservedObject var gameLogic: InfinityGameLogic
    let onBack: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var dragOffset = CGSize.zero
    
    private let cellSize: CGFloat = 50  // Más pequeño para que quepa 5x5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo
                Color.purple.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Tablero con pan & zoom
                    boardView
                    
                    // Controles y info
                    controlsView
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // Botón volver
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Volver")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.2))
                    )
                }
                .buttonAnimation()
                
                Spacer()
                
                // Indicador de nivel de IA
                if gameLogic.infiniteGameMode == .vsAI {
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.caption)
                        Text("IA: \(gameLogic.aiLevel.title)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Título
            VStack(spacing: 4) {
                Text("Infinite Tic-Tac-Toe")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Tamaño actual del tablero
                let rows = gameLogic.infiniteBoard.maxRow - gameLogic.infiniteBoard.minRow + 1
                let cols = gameLogic.infiniteBoard.maxCol - gameLogic.infiniteBoard.minCol + 1
                
                Text("Tablero: \(rows)×\(cols)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            
            // Subtítulo con instrucciones
            Text("5 en línea para ganar • Pellizca para zoom")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 20)
        .padding(.bottom, 15)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Board
    
    private var boardView: some View {
        GeometryReader { geometry in
            let boardWidth = CGFloat(gameLogic.infiniteBoard.maxCol - gameLogic.infiniteBoard.minCol + 1) * cellSize
            let boardHeight = CGFloat(gameLogic.infiniteBoard.maxRow - gameLogic.infiniteBoard.minRow + 1) * cellSize
            
            ZStack {
                // Tablero
                VStack(spacing: 0) {
                    ForEach(gameLogic.infiniteBoard.minRow...gameLogic.infiniteBoard.maxRow, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(gameLogic.infiniteBoard.minCol...gameLogic.infiniteBoard.maxCol, id: \.self) { col in
                                InfiniteCellView(
                                    position: GridPosition(row: row, col: col),
                                    player: gameLogic.infiniteBoard[GridPosition(row: row, col: col)],
                                    cellSize: cellSize
                                ) {
                                    gameLogic.makeInfiniteMove(at: GridPosition(row: row, col: col))
                                }
                            }
                        }
                    }
                }
                .frame(width: boardWidth, height: boardHeight)
                .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                .scaleEffect(scale)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                            scale = min(max(scale, 0.5), 2.0) // Límites de zoom
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                        }
                )
                
                // Overlay de victoria
                if gameLogic.infiniteIsGameOver {
                    victoryOverlay
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }
    
    private var victoryOverlay: some View {
        VStack(spacing: 20) {
            Text(victoryMessage)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.8))
                        .shadow(radius: 20)
                )
            
            Button(action: {
                withAnimation {
                    gameLogic.resetInfiniteTicTacToe()
                    resetView()
                }
            }) {
                Text("Nueva Partida")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonAnimation()
        }
    }
    
    private var victoryMessage: String {
        if gameLogic.infiniteWinner == .player1 {
            return "🎉 ¡Luna ganó! 🌙"
        } else if gameLogic.infiniteWinner == .player2 {
            if gameLogic.infiniteGameMode == .vsAI {
                return "🤖 La IA ganó"
            } else {
                return "⭐ ¡Papá ganó!"
            }
        } else {
            return "🏆 ¡Empate!"
        }
    }
    
    // MARK: - Controls
    
    private var controlsView: some View {
        VStack(spacing: 15) {
            // Estado del juego
            if !gameLogic.infiniteIsGameOver {
                HStack(spacing: 8) {
                    Circle()
                        .fill(gameLogic.infiniteCurrentPlayer == .player1 ? Color.pink : Color.purple)
                        .frame(width: 12, height: 12)
                    
                    Text("Turno de \(gameLogic.infiniteCurrentPlayer == .player1 ? "Luna 🌙" : "Papá ⭐")")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                )
            }
            
            // Botones
            HStack(spacing: 15) {
                // Reset zoom
                Button(action: resetView) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.title3)
                        Text("Resetear Vista")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .buttonAnimation()
                
                // Cambiar modo
                Button(action: {
                    gameLogic.infiniteGameMode = gameLogic.infiniteGameMode == .vsAI ? .vsPlayer : .vsAI
                    gameLogic.resetInfiniteTicTacToe()
                    resetView()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: gameLogic.infiniteGameMode == .vsAI ? "person.2.fill" : "brain")
                            .font(.title3)
                        Text(gameLogic.infiniteGameMode == .vsAI ? "vs Jugador" : "vs IA")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .buttonAnimation()
                
                // Nueva partida
                Button(action: {
                    withAnimation {
                        gameLogic.resetInfiniteTicTacToe()
                        resetView()
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                        Text("Nueva Partida")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .buttonAnimation()
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helpers
    
    private func resetView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            offset = .zero
            scale = 1.0
        }
    }
}

// MARK: - Infinite Cell View

struct InfiniteCellView: View {
    let position: GridPosition
    let player: Player
    let cellSize: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Fondo
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: cellSize, height: cellSize)
                
                // Bordes
                Rectangle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: cellSize, height: cellSize)
                
                // Símbolo del jugador
                if player != .none {
                    Text(player == .player1 ? "○" : "×")
                        .font(.system(size: cellSize * 0.6, weight: .bold))
                        .foregroundColor(player == .player1 ? .pink : .purple)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Preview

#Preview {
    InfiniteTicTacToeView(
        gameLogic: InfinityGameLogic(),
        onBack: {}
    )
}
