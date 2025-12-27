import SwiftUI

struct MenuView: View {
    @StateObject private var gameLogic = GameLogic()

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo degradado
                LinearGradient.mainMenu
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 20)

                        // Header con título y configuración
                        headerSection

                        // Banner de anuncio
                        menuAdSection

                        // Tarjetas de modos de juego
                        gameModesSection

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .playing && gameLogic.gameMode != .infinityLevel)) {
            GameView(gameLogic: gameLogic)
        }
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .playing && gameLogic.gameMode == .infinityLevel)) {
            InfinityPapaModeView(mainGameLogic: gameLogic)
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

    // MARK: - Menu Ad Section
    private var menuAdSection: some View {
        Group {
            if !PurchaseManager.shared.hasRemovedAds {
                ZStack {
                    // Placeholder background
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 60)

                    Text(" ")
                        .font(.caption2)
                        .foregroundColor(.clear)
                        .onAppear {
                            print("🔍 Menu banner placeholder appeared")
                        }

                    // Banner ad on top
                    AdMobBannerView(adUnitID: "ca-app-pub-3258994800717071/5955178067") // Real Banner ID
                        .frame(height: 60)
                }
                .frame(height: 60)
                .cornerRadius(15)
            } else {
                // Espacio mínimo cuando los anuncios están removidos
                Color.clear.frame(height: 8)
            }
        }
    }

    // MARK: - Game Modes Section
    private var gameModesSection: some View {
        VStack(spacing: 20) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                GameModeCard(mode: mode) {
                    if mode == .infinityLevel {
                        gameLogic.gameMode = .infinityLevel
                        gameLogic.gameState = .playing
                    } else {
                        gameLogic.startNewGame(mode: mode)
                    }
                }
            }
        }
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
            .doubleShadow()
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.3), value: UUID())
        .drawingGroup()
    }

    private func gradientForMode(_ mode: GameMode) -> LinearGradient {
        switch mode {
        case .lunaMode:
            return LinearGradient.menuCardLuna
        case .unbeatableMode:
            return LinearGradient.menuCardUnbeatable
        case .infinityLevel:
            return LinearGradient.menuCardInfinity
        }
    }
}


// MARK: - Preview
#Preview {
    MenuView()
}