import SwiftUI

struct MenuView: View {
    @StateObject private var gameLogic = GameLogic()

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo degradado
                LinearGradient.lunaMode
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 20)

                        // Header con título y configuración
                        headerSection

                        // Tarjetas de modos de juego
                        gameModesSection

                        // Emojis decorativos
                        decorativeEmojis

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .playing)) {
            GameView(gameLogic: gameLogic)
        }
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .settings)) {
            SettingsView(gameLogic: gameLogic)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 15) {
            HStack {
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
                                .fill(Color.black.opacity(0.2))
                        )
                }
                .buttonAnimation()
            }

            // Título principal
            HStack {
                Text("🎮")
                    .font(.largeTitle)

                Text("Tic-Tac-Toe")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("🎮")
                    .font(.largeTitle)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Game Modes Section
    private var gameModesSection: some View {
        VStack(spacing: 20) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                GameModeCard(mode: mode) {
                    gameLogic.startNewGame(mode: mode)
                }
            }
        }
    }

    // MARK: - Decorative Emojis
    private var decorativeEmojis: some View {
        HStack(spacing: 40) {
            Text("💕")
                .font(.title)

            Text("🌈")
                .font(.title)

            Text("✨")
                .font(.title)
        }
        .opacity(0.8)
    }
}

// MARK: - Game Mode Card Component
struct GameModeCard: View {
    let mode: GameMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                // Header con ícono y flecha
                HStack {
                    Text(mode.icon)
                        .font(.largeTitle)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Títulos
                VStack(alignment: .leading, spacing: 5) {
                    Text(mode.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(mode.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                // Características
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(mode.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)

                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))

                            Spacer()
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradientForMode(mode))
            )
            .cardShadow()
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: UUID())
    }

    private func gradientForMode(_ mode: GameMode) -> LinearGradient {
        switch mode {
        case .lunaMode:
            return LinearGradient.menuCardLuna
        case .unbeatableMode:
            return LinearGradient.menuCardUnbeatable
        }
    }
}

// MARK: - Preview
#Preview {
    MenuView()
}