import SwiftUI

struct GameView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var interstitialAdManager = InterstitialAdManager()
    @State private var showMagicalEffect = false
    @State private var showConfetti = false
    @State private var gamesPlayedCount = 0

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
                        if (gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel) && gameLogic.isGameOver && gameLogic.winner == .player1 {
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

                    // Efectos mágicos para Luna Mode e Infinity Level
                    if (gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel) && showMagicalEffect {
                        magicalEffectsOverlay(in: geometry)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            gameLogic.resetGame()
            print("🔍 GameView onAppear - PurchaseManager.shared.hasRemovedAds: \(PurchaseManager.shared.hasRemovedAds)")
        }
        .onChange(of: gameLogic.isGameOver) { _, isGameOver in
            if isGameOver && (gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel) {
                print("🎊 CONFETTI TRIGGERED: Luna Mode / Infinity Level End!")
                triggerMagicalEffect()
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                    print("🎊 CONFETTI STOPPED")
                }
            }
            if isGameOver {
                triggerWinHaptic()

                // Mostrar anuncio intersticial cada 10 partidas (si no se han removido los anuncios)
                gamesPlayedCount += 1
                print("🎮 Games played: \(gamesPlayedCount)")
                if interstitialAdManager.shouldShowAdAfterGames(gamesPlayedCount) {
                    print("🎬 Should show interstitial ad now!")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        interstitialAdManager.presentInterstitialAd()
                    }
                }
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
        case .infinityLevel:
            return LinearGradient.lunaMode // Usa el mismo gradiente que Luna Mode
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
                    Text((gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel) ? "Menú" : "Menu")
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
        case .infinityLevel:
            return "∞ Infinity Level"
        }
    }

    // MARK: - Advertisement Section
    private var advertisementSection: some View {
        let hasRemovedAds = PurchaseManager.shared.hasRemovedAds

        return Group {
            if !hasRemovedAds {
                ZStack {
                    // Placeholder background
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 60)

                    Text(" ")
                        .font(.caption2)
                        .foregroundColor(.clear)
                        .onAppear {
                            print("🔍 Advertisement placeholder appeared, hasRemovedAds: \(hasRemovedAds)")
                        }

                    // Banner ad on top (cuando cargue, cubrirá el placeholder)
                    AdMobBannerView(adUnitID: "ca-app-pub-3258994800717071/5955178067") // Production Banner ID
                        .frame(height: 60)
                }
                .frame(height: 60)
                .cornerRadius(15)
            } else {
                // Espacio mínimo cuando los anuncios están removidos
                Color.clear.frame(height: 8)
                    .onAppear {
                        print("🚫 Ads removed section appeared")
                    }
            }
        }
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
        if gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel {
            return AnyShapeStyle(.ultraThinMaterial)
        } else {
            return AnyShapeStyle(Color.white.opacity(0.2))
        }
    }

    // MARK: - Game Board
    private func gameBoard(for geometry: GeometryProxy) -> some View {
        let boardSize: CGFloat = min(geometry.size.width - 40, 350)
        let cellSize: CGFloat = boardSize / 3

        return VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { col in
                        ZStack {
                            // Celda con fondo blanco y borde
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(gridBorderColor, lineWidth: 1.5)
                                )

                            // Contenido de la celda (emoji del jugador)
                            GameCell(
                                emoji: gameLogic.getCellEmoji(row: row, col: col),
                                gameMode: gameLogic.gameMode,
                                cellSize: cellSize
                            ) {
                                gameLogic.makeMove(row: row, col: col)
                            }
                        }
                        .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private var gridBorderColor: Color {
        switch gameLogic.gameMode {
        case .lunaMode:
            return Color.pink.opacity(0.6)
        case .unbeatableMode:
            return Color.gray.opacity(0.8)
        case .infinityLevel:
            return Color.purple.opacity(0.6)
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
        case .infinityLevel:
            return "∞"
        }
    }

    private var newGameButtonText: String {
        switch gameLogic.gameMode {
        case .lunaMode:
            return "Nueva Partida"
        case .unbeatableMode:
            return "New Game"
        case .infinityLevel:
            return "Nueva Partida ∞"
        }
    }

    private var newGameButtonGradient: LinearGradient {
        switch gameLogic.gameMode {
        case .lunaMode:
            return LinearGradient.lunaModeButton
        case .unbeatableMode:
            return LinearGradient.unbeatableModeButton
        case .infinityLevel:
            return LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .leading, endPoint: .trailing)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
