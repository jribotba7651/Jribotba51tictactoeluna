import SwiftUI

struct GameView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared
    @State private var showMagicalEffect = false

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo según el modo de juego
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer(minLength: 10)

                    // Header
                    headerSection

                    // Espacio de anuncio
                    advertisementSection

                    // Marcadores
                    scoreSection

                    // Mensaje del juego
                    gameMessageSection

                    // Tablero de juego
                    gameBoard

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

                    // Botón de nueva partida
                    newGameButton

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)

                // Efectos mágicos para Luna Mode
                if gameLogic.gameMode == .lunaMode && showMagicalEffect {
                    magicalEffectsOverlay
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
            .frame(height: 80)
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
                icon: dataManager.getPlayerEmoji(for: .player1),
                count: gameLogic.getPlayerWins(for: .player1),
                color: .scorePlayer1
            )

            // Empates
            ScoreCard(
                icon: "🏆",
                count: gameLogic.getPlayerWins(for: .none),
                color: .scoreDraw
            )

            // Score del jugador 2
            ScoreCard(
                icon: dataManager.getPlayerEmoji(for: .player2),
                count: gameLogic.getPlayerWins(for: .player2),
                color: .scorePlayer2
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
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.2))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
    }

    // MARK: - Game Board
    private var gameBoard: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .frame(width: 350, height: 350)
                .doubleShadow()

            // Grid Lines (non-interactive)
            TicTacToeGridLines(gameMode: gameLogic.gameMode)

            // Game Cells (interactive buttons - MUST be last/on top)
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            GameCell(
                                emoji: gameLogic.getCellEmoji(row: row, col: col),
                                gameMode: gameLogic.gameMode
                            ) {
                                gameLogic.makeMove(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .frame(width: 350, height: 350)
            .allowsHitTesting(true)
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
            .padding(.vertical, 18)
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
            return "❤️"
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


    // MARK: - Clean Confetti Effects (legacy - keeping for other modes)
    private var magicalEffectsOverlay: some View {
        ZStack {
            // Fluid colored circles confetti
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(confettiColors.randomElement() ?? Color.pink)
                    .frame(width: 12, height: 12)
                    .position(
                        x: CGFloat.random(in: 30...UIScreen.main.bounds.width - 30),
                        y: showMagicalEffect ? UIScreen.main.bounds.height + 50 : CGFloat.random(in: -50...0)
                    )
                    .opacity(showMagicalEffect ? 0.8 : 0)
                    .animation(
                        .linear(duration: Double.random(in: 2.0...3.5))
                        .delay(Double(index) * 0.1),
                        value: showMagicalEffect
                    )
            }
        }
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

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.largeTitle)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(color.opacity(0.8))
                .doubleShadow()
        )
    }
}

// MARK: - Grid Lines Component
struct TicTacToeGridLines: View {
    let gameMode: GameMode

    var body: some View {
        ZStack {
            // Vertical lines
            HStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(lineGradient)
                    .frame(width: 5, height: 270)
                Spacer()
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(lineGradient)
                    .frame(width: 5, height: 270)
                Spacer()
            }
            .frame(width: 350)

            // Horizontal lines
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(lineGradient)
                    .frame(width: 270, height: 5)
                Spacer()
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(lineGradient)
                    .frame(width: 270, height: 5)
                Spacer()
            }
            .frame(height: 350)
        }
        .drawingGroup()
        .allowsHitTesting(false)
    }

    private var lineGradient: LinearGradient {
        switch gameMode {
        case .lunaMode:
            return LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.6)]),
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
}

// MARK: - Game Cell Component
struct GameCell: View {
    let emoji: String
    let gameMode: GameMode
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            Text(emoji)
                .font(.system(size: 45))
                .fontWeight(.bold)
                .frame(width: 116, height: 116)
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
