import SwiftUI

// MARK: - ThreeInOne Localization Helpers
func localizedThreeInOneString(for key: String) -> String {
    let isSpanish = UserDefaults.standard.string(forKey: "AppLanguage") == "es"
    let strings: [String: String] = [
        "three_in_one_puzzle": isSpanish ? "Rompecabezas Tres en Uno" : "Three-in-One Puzzle",
        "choose_variant": isSpanish ? "Elige una variante" : "Choose a variant",
        "back": isSpanish ? "Volver" : "Back",
        "player_turn": isSpanish ? "Turno de Jugador" : "Player's turn",
        "player_1": isSpanish ? "Jugador 1" : "Player 1",
        "player_2": isSpanish ? "Jugador 2" : "Player 2",
        "player_1_won": isSpanish ? "🎉 ¡Jugador 1 ganó!" : "🎉 Player 1 won!",
        "player_2_won": isSpanish ? "🎊 ¡Jugador 2 ganó!" : "🎊 Player 2 won!",
        "draw": isSpanish ? "🤝 ¡Empate!" : "🤝 Draw!",
        "time_remaining": isSpanish ? "Tiempo restante" : "Time remaining",
        "new_game": isSpanish ? "Nueva Partida" : "New Game"
    ]
    return strings[key] ?? key
}

struct ThreeInOneView: View {
    @ObservedObject var gameLogic: InfinityGameLogic
    let onBack: () -> Void
    
    @State private var showingVariantSelector = true
    @State private var showingPlayerCountPicker = false
    
    var body: some View {
        ZStack {
            // Fondo
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.cyan.opacity(0.3),
                    Color.blue.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showingVariantSelector {
                variantSelectorView
            } else {
                gamePlayView
            }
        }
    }
    
    // MARK: - Variant Selector
    
    private var variantSelectorView: some View {
        VStack(spacing: 0) {
            // Header
            headerView(title: localizedThreeInOneString(for: "three_in_one_puzzle"))
            
            // Selector de variantes
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 20)
                    
                    Text(localizedThreeInOneString(for: "choose_variant"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    ForEach(ThreeInOneVariant.allCases, id: \.self) { variant in
                        VariantCard(variant: variant) {
                            selectVariant(variant)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Gameplay View
    
    private var gamePlayView: some View {
        VStack(spacing: 0) {
            // Header
            headerView(title: gameLogic.threeInOneState.variant.displayName)
            
            Spacer()
            
            // Estado del juego
            gameStatusView
            
            // Tablero
            boardView
                .padding(.vertical, 30)
            
            // Timer (solo para modo cronometrado)
            if gameLogic.threeInOneState.variant == .timed {
                timerView
            }
            
            Spacer()
            
            // Controles
            controlsView
                .padding(.bottom, 30)
        }
    }
    
    // MARK: - Header
    
    private func headerView(title: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                // Botón volver
                Button(action: {
                    if showingVariantSelector {
                        onBack()
                    } else {
                        withAnimation {
                            showingVariantSelector = true
                            gameLogic.resetThreeInOne()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(localizedThreeInOneString(for: "back"))
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
            }
            .padding(.horizontal, 20)
            
            // Título
            HStack(spacing: 8) {
                Text("🎯")
                    .font(.title)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Mostrar descripción de la variante cuando está jugando
            if !showingVariantSelector {
                Text(gameLogic.threeInOneState.variant.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 15)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Game Status
    
    private var gameStatusView: some View {
        Group {
            if gameLogic.threeInOneGameOver {
                Text(victoryMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
            } else {
                HStack(spacing: 8) {
                    Circle()
                        .fill(gameLogic.threeInOneState.currentPlayer == .player1 ? Color.pink : Color.cyan)
                        .frame(width: 12, height: 12)
                    
                    Text("\(localizedThreeInOneString(for: "player_turn")) \(gameLogic.threeInOneState.currentPlayer == .player1 ? localizedThreeInOneString(for: "player_1") : localizedThreeInOneString(for: "player_2"))")
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
        }
    }
    
    private var victoryMessage: String {
        if gameLogic.threeInOneWinner == .player1 {
            return localizedThreeInOneString(for: "player_1_won")
        } else if gameLogic.threeInOneWinner == .player2 {
            return localizedThreeInOneString(for: "player_2_won")
        } else {
            return localizedThreeInOneString(for: "draw")
        }
    }
    
    // MARK: - Board

    private var boardView: some View {
        GeometryReader { geometry in
            let availableSize = min(geometry.size.width - 40, geometry.size.height - 100)
            let boardSize = availableSize
            let cellSize = boardSize / 3

            VStack(spacing: 0) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)

                    // Grid lines (# shape)
                    threeInOneGridLines(cellSize: cellSize)

                    // Grid cells
                    VStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<3, id: \.self) { col in
                                    ThreeInOneGameGridCell(
                                        row: row,
                                        col: col,
                                        player: gameLogic.threeInOneState.board[row, col].player,
                                        cellSize: cellSize
                                    ) {
                                        gameLogic.makeThreeInOneMove(row: row, col: col)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(width: boardSize, height: boardSize)
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: 350)  // Altura fija para el contenedor
        .padding(.horizontal, 20)
    }

    private func threeInOneGridLines(cellSize: CGFloat) -> some View {
        ZStack {
            // Vertical lines (excluding borders)
            ForEach(1..<3, id: \.self) { index in
                Rectangle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 2.5, height: cellSize * 3)
                    .offset(x: CGFloat(index) * cellSize - (cellSize * 1.5) + (cellSize / 2) - 1.25)
            }

            // Horizontal lines (excluding borders)
            ForEach(1..<3, id: \.self) { index in
                Rectangle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: cellSize * 3, height: 2.5)
                    .offset(y: CGFloat(index) * cellSize - (cellSize * 1.5) + (cellSize / 2) - 1.25)
            }
        }
    }
    
    // MARK: - Timer
    
    private var timerView: some View {
        VStack(spacing: 8) {
            Text(localizedThreeInOneString(for: "time_remaining"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(gameLogic.threeInOneState.timeRemaining)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(gameLogic.threeInOneState.timeRemaining <= 10 ? .red : .white)
                .monospacedDigit()
            
            ProgressView(value: Double(gameLogic.threeInOneState.timeRemaining), total: 30)
                .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                .frame(width: 200)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
        )
    }
    
    // MARK: - Controls
    
    private var controlsView: some View {
        VStack(spacing: 15) {
            // Botón nueva partida
            Button(action: {
                withAnimation {
                    gameLogic.resetThreeInOne()
                    gameLogic.selectThreeInOneVariant(gameLogic.threeInOneState.variant)
                }
            }) {
                Text(localizedThreeInOneString(for: "new_game"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonAnimation()
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helpers
    
    private func selectVariant(_ variant: ThreeInOneVariant) {
        gameLogic.selectThreeInOneVariant(variant)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingVariantSelector = false
        }
    }
}

// MARK: - Variant Card

struct VariantCard: View {
    let variant: ThreeInOneVariant
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icono
                Image(systemName: variant.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(variant.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(variant.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.2))
            )
        }
        .buttonAnimation()
    }
}

// MARK: - Three-In-One Game Grid Cell Component

struct ThreeInOneGameGridCell: View {
    let row: Int
    let col: Int
    let player: Player
    let cellSize: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Transparent background for touch target
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: cellSize, height: cellSize)

                // Player symbol
                if player != .none {
                    Text(player == .player1 ? "○" : "×")
                        .font(.system(size: cellSize * 0.5, weight: .bold))
                        .foregroundColor(player == .player1 ? .pink : .cyan)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ThreeInOneView(
        gameLogic: InfinityGameLogic(),
        onBack: {}
    )
}
