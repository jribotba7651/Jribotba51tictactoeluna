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
                color: .pink
            )

            // Empates
            ScoreCard(
                icon: "🏆",
                count: gameLogic.getPlayerWins(for: .none),
                color: .orange
            )

            // Score del jugador 2
            ScoreCard(
                icon: dataManager.getPlayerEmoji(for: .player2),
                count: gameLogic.getPlayerWins(for: .player2),
                color: gameLogic.gameMode == .lunaMode ? .blue : .green
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
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 8) {
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
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .cardShadow()
        )
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
        .cardShadow()
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

    // MARK: - Magical Effects
    private var magicalEffectsOverlay: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { _ in
                Text(String.randomCelebrationEmoji())
                    .font(.largeTitle)
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...600)
                    )
                    .opacity(showMagicalEffect ? 1 : 0)
                    .scaleEffect(showMagicalEffect ? 1.5 : 0.1)
                    .animation(
                        .easeOut(duration: 1.0).delay(Double.random(in: 0...0.5)),
                        value: showMagicalEffect
                    )
            }
        }
        .allowsHitTesting(false)
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
                .cardShadow()
        )
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
                .font(.system(size: 40))
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(strokeColor, lineWidth: strokeWidth)
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: emoji)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
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

    private var strokeColor: Color {
        switch gameMode {
        case .lunaMode:
            return Color.pink.opacity(0.6)
        case .unbeatableMode:
            return Color.black
        }
    }

    private var strokeWidth: CGFloat {
        switch gameMode {
        case .lunaMode:
            return 2
        case .unbeatableMode:
            return 3
        }
    }
}

// MARK: - Preview
#Preview {
    GameView(gameLogic: GameLogic())
}