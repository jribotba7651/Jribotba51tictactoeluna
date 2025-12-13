import SwiftUI

struct GameView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared
    @State private var showMagicalEffect = false
    @State private var showConfetti = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Fondo según el modo de juego
                    backgroundGradient
                        .ignoresSafeArea()

                    VStack(spacing: 12) {
                        Spacer(minLength: 5)

                        // Header
                        headerSection

                        // Espacio de anuncio
                        advertisementSection

                        // Marcadores
                        scoreSection

                        // Mensaje cuando Luna gana
                        if gameLogic.gameMode == .lunaMode && gameLogic.isGameOver && gameLogic.winner == .player1 {
                            Text("¡Luna ganó! ✨🎉")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.pink.opacity(0.3))
                                )
                        }

                        // Mensaje del juego
                        gameMessageSection

                        // Tablero de juego
                        gameBoard(for: geometry)

                        // Botón de nueva partida
                        newGameButton

                        Spacer(minLength: 10)
                    }
                    .padding(.horizontal, 20)
                    .confetti(isActive: $showConfetti)

                    // Efectos mágicos para Luna Mode
                    if gameLogic.gameMode == .lunaMode && showMagicalEffect {
                        magicalEffectsOverlay(in: geometry)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            gameLogic.resetGame()
        }
        .onChange(of: gameLogic.isGameOver) { _, isGameOver in
            if isGameOver && gameLogic.winner == .player1 && gameLogic.gameMode == .lunaMode {
                triggerMagicalEffect()
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                }
            }
            if isGameOver {
                triggerWinHaptic()
            }
        }
    }

    // MARK: - Background
    private var backgroundGradient: LinearGradient {
        switch gameLogic.gameMode {
        case .lunaMode:
            return LinearGradient.lunaMode
        case .unbeatableMode:
            return LinearGradient.unbeatableMode
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Botón de regresar
            Button(action: {
                gameLogic.backToMenu()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(gameLogic.gameMode == .lunaMode ? "Menú" : "Menu")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .buttonAnimation()

            Spacer()

            // Título del modo
            Text(gameModeTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            // Botón de configuración
            Button(action: {
                gameLogic.showSettings()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .buttonAnimation()
        }
    }

    private var gameModeTitle: String {
        switch gameLogic.gameMode {
        case .lunaMode:
            return "🌙 Luna Mode"
        case .unbeatableMode:
            return "🤖 Unbeatable Mode"
        }
    }

    // MARK: - Advertisement Section
    private var advertisementSection: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.black.opacity(0.1))
            .frame(height: 60)
            .overlay(
                Text("Advertisement")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
            )
    }

    // MARK: - Score Section
    private var scoreSection: some View {
        HStack(spacing: 15) {
            // Score del jugador 1
            ScoreCard(
                icon: gameLogic.gameMode == .unbeatableMode ? "○" : dataManager.getPlayerEmoji(for: .player1),
                count: gameLogic.getPlayerWins(for: .player1),
                color: Color(hex: "#10B981"), // Verde esmeralda
                gameMode: gameLogic.gameMode
            )

            // Empates
            ScoreCard(
                icon: "🏆",
                count: gameLogic.getPlayerWins(for: .none),
                color: Color(hex: "#FB923C"), // Naranja
                gameMode: gameLogic.gameMode
            )

            // Score del jugador 2
            ScoreCard(
                icon: gameLogic.gameMode == .unbeatableMode ? "×" : dataManager.getPlayerEmoji(for: .player2),
                count: gameLogic.getPlayerWins(for: .player2),
                color: Color(hex: "#60A5FA"), // Azul
                gameMode: gameLogic.gameMode
            )
        }
    }

    // MARK: - Game Message Section
    private var gameMessageSection: some View {
        Text(gameLogic.gameMessage)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(gameMessageBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
    }

    private var gameMessageBackground: AnyShapeStyle {
        if gameLogic.gameMode == .lunaMode {
            return AnyShapeStyle(.ultraThinMaterial)
        } else {
            return AnyShapeStyle(Color.white.opacity(0.2))
        }
    }

    // MARK: - Game Board
    private func gameBoard(for geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let screenHeight = geometry.size.height
        let boardSize = min(screenWidth * 0.92, screenHeight * 0.50, 450)
        let cellSize = (boardSize - 10) / 3
        let lineLength = boardSize * 0.8

        return ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .frame(width: boardSize, height: boardSize)
                .doubleShadow()

            // Grid Lines (non-interactive)
            ZStack {
                // Líneas verticales
                HStack {
                    Spacer()
                        .frame(width: cellSize + 5)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(lineGradient)
                        .frame(width: 5, height: lineLength)

                    Spacer()
                        .frame(width: cellSize)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(lineGradient)
                        .frame(width: 5, height: lineLength)

                    Spacer()
                        .frame(width: cellSize + 5)
                }

                // Líneas horizontales
                VStack {
                    Spacer()
                        .frame(height: cellSize + 5)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(lineGradient)
                        .frame(width: lineLength, height: 5)

                    Spacer()
                        .frame(height: cellSize)

                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(lineGradient)
                        .frame(width: lineLength, height: 5)

                    Spacer()
                        .frame(height: cellSize + 5)
                }
            }
            .allowsHitTesting(false)

            // Game Cells (interactive buttons - MUST be last/on top)
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            GameCell(
                                emoji: gameLogic.getCellEmoji(row: row, col: col),
                                gameMode: gameLogic.gameMode,
                                cellSize: cellSize
                            ) {
                                gameLogic.makeMove(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .frame(width: boardSize, height: boardSize)
            .allowsHitTesting(true)
        }
    }

    private var lineGradient: LinearGradient {
        switch gameLogic.gameMode {
        case .lunaMode:
            return LinearGradient(
                gradient: Gradient(colors: [Color.pink, Color.purple, Color.orange]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .unbeatableMode:
            return LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - New Game Button
    private var newGameButton: some View {
        Button(action: {
            gameLogic.resetGame()
        }) {
            HStack {
                Text(newGameButtonIcon)
                    .font(.title2)

                Text(newGameButtonText)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(newGameButtonGradient)
            )
        }
        .buttonAnimation()
        .doubleShadow()
    }

    private var newGameButtonIcon: String {
        switch gameLogic.gameMode {
        case .lunaMode:
            return "💓"
        case .unbeatableMode:
            return "🔄"
        }
    }

    private var newGameButtonText: String {
        switch gameLogic.gameMode {
        case .lunaMode:
            return "Nueva Partida"
        case .unbeatableMode:
            return "New Game"
        }
    }

    private var newGameButtonGradient: LinearGradient {
        switch gameLogic.gameMode {
        case .lunaMode:
            return LinearGradient.lunaModeButton
        case .unbeatableMode:
            return LinearGradient.unbeatableModeButton
        }
    }


    // MARK: - Confetti Effects
    private func magicalEffectsOverlay(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Círculos de colores cayendo
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(confettiColors.randomElement() ?? Color.pink)
                    .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                    .offset(
                        x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                        y: showMagicalEffect ? geometry.size.height : CGFloat.random(in: -100...0)
                    )
                    .opacity(showMagicalEffect ? 0.9 : 0)
                    .animation(
                        .linear(duration: Double.random(in: 1.5...3.0))
                        .delay(Double(index) * 0.08),
                        value: showMagicalEffect
                    )
            }

            // Estrellas girando
            ForEach(0..<15, id: \.self) { index in
                Text("✨")
                    .font(.system(size: CGFloat.random(in: 12...16)))
                    .offset(
                        x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                        y: showMagicalEffect ? geometry.size.height : CGFloat.random(in: -100...0)
                    )
                    .opacity(showMagicalEffect ? 1.0 : 0)
                    .rotationEffect(.degrees(showMagicalEffect ? Double.random(in: 0...720) : 0))
                    .animation(
                        .linear(duration: Double.random(in: 2.0...4.0))
                        .delay(Double(index) * 0.1),
                        value: showMagicalEffect
                    )
            }
        }
        .frame(height: 0)
        .clipped()
        .allowsHitTesting(false)
    }

    private var confettiColors: [Color] {
        [.pink, .purple, .orange, .blue, .green, .yellow, .red]
    }

    // MARK: - Helper Methods
    private func triggerMagicalEffect() {
        withAnimation {
            showMagicalEffect = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showMagicalEffect = false
            }
        }
    }

    private func triggerWinHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactFeedback.impactOccurred()
        }
        #endif
    }
}

// MARK: - Score Card Component
struct ScoreCard: View {
    let icon: String
    let count: Int
    let color: Color
    let gameMode: GameMode

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.largeTitle)
                .foregroundColor(iconColor)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.8))
                .doubleShadow()
        )
    }

    private var iconColor: Color {
        if gameMode == .unbeatableMode {
            if icon == "○" {
                return .gray
            } else if icon == "×" {
                return .black
            }
        }
        return .white // Color por defecto
    }
}


// MARK: - Game Cell Component
struct GameCell: View {
    let emoji: String
    let gameMode: GameMode
    let cellSize: CGFloat
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            Text(emoji)
                .font(.system(size: cellSize * 0.4))
                .fontWeight(.bold)
                .foregroundColor(symbolColor)
                .frame(width: cellSize, height: cellSize)
                .contentShape(Rectangle())
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isPressed)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: emoji)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    private var symbolColor: Color {
        if gameMode == .unbeatableMode {
            if emoji == "○" {
                return Color.gray // Gris para Unbeatable (○)
            } else if emoji == "×" {
                return Color.black // Negro para Unbeatable (×)
            }
        }
        return Color.primary // Color por defecto para otros modos
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
}

// MARK: - Preview
#Preview {
    GameView(gameLogic: GameLogic())
}
