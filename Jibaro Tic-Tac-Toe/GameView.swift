import SwiftUI
import Foundation

// MARK: - Localization Helpers REMOVED
// Logic consolidated into LocalizationManager

struct GameView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var interstitialAdManager = InterstitialAdManager()
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
                        if (gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel) && gameLogic.isGameOver && gameLogic.winner == .player1 {
                            Text("luna_won".localized)
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
        .onChange(of: gameLogic.isGameOver) { oldValue, newValue in
            // Solo procesar cuando el juego cambia de false a true (juego terminado)
            guard !oldValue && newValue else { return }
            
            if (gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel) {
                print("🎊 CONFETTI TRIGGERED: Luna Mode / Infinity Level End!")
                triggerMagicalEffect()
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                    print("🎊 CONFETTI STOPPED")
                }
            }
            
            triggerWinHaptic()

            // Mostrar anuncio intersticial cada 10 partidas (si no se han removido los anuncios)
            dataManager.gamesPlayedCount += 1
            let currentCount = dataManager.gamesPlayedCount
            print("🎮 Games played: \(currentCount) | Game mode: \(gameLogic.gameMode)")
            print("🎮 PurchaseManager.hasRemovedAds: \(PurchaseManager.shared.hasRemovedAds)")
            print("🎮 InterstitialAdManager.isReady: \(interstitialAdManager.isReady)")
            
            // Verificar si debemos mostrar el anuncio
            let shouldShow = interstitialAdManager.shouldShowAdAfterGames(currentCount)
            print("🎮 shouldShowAdAfterGames returned: \(shouldShow)")
            
            if shouldShow {
                print("🎬 Should show interstitial ad now! (Game #\(currentCount))")
                // Esperar un poco para que el usuario vea el resultado del juego
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Verificar nuevamente antes de mostrar (por si el usuario compró remover anuncios)
                    let stillShouldShow = interstitialAdManager.shouldShowAdAfterGames(currentCount)
                    print("🎬 After delay, shouldShow: \(stillShouldShow)")
                    if stillShouldShow {
                        print("🎬 Calling presentInterstitialAd()")
                        interstitialAdManager.presentInterstitialAd()
                    } else {
                        print("🚫 Ad not shown - user may have removed ads or ad not ready")
                    }
                }
            } else {
                let nextAdAt = ((currentCount / 10) + 1) * 10
                let remainder = currentCount % 10
                print("📊 Next ad will show at game #\(nextAdAt) (currently at #\(currentCount), remainder: \(remainder))")
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
                    Text("menu".localized)
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
            return "luna_mode".localized
        case .unbeatableMode:
            return "unbeatable_mode".localized
        case .infinityLevel:
            return "infinity_level".localized
        }
    }

    // MARK: - Advertisement Section
    private var advertisementSection: some View {
        let hasRemovedAds = PurchaseManager.shared.hasRemovedAds

        return Group {
            // Mostrar banner en TODOS los modos de juego (lunaMode, unbeatableMode, infinityLevel)
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
                            print("🔍 Advertisement placeholder appeared, hasRemovedAds: \(hasRemovedAds), gameMode: \(gameLogic.gameMode)")
                        }

                    // Banner ad on top (cuando cargue, cubrirá el placeholder)
                    AdMobBannerView(adUnitID: "ca-app-pub-3258994800717071/5955178067") // Production Banner ID
                        .frame(height: 60)
                        .id("banner-\(gameLogic.gameMode)") // Forzar recreación cuando cambia el modo
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
        if gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel || gameLogic.gameMode == .unbeatableMode {
            return AnyShapeStyle(.ultraThinMaterial)
        } else {
            return AnyShapeStyle(Color.white.opacity(0.2))
        }
    }

    // MARK: - Game Board
    private func gameBoard(for geometry: GeometryProxy) -> some View {
        let boardSize: CGFloat = min(geometry.size.width - 40, 350)
        let cellSize: CGFloat = boardSize / 3

        return ZStack {
            // Background
            Rectangle()
                .fill(Color.white.opacity(0.95))
                .frame(width: boardSize, height: boardSize)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

            // Grid lines (# shape)
            gameGridLines(cellSize: cellSize)

            // Grid cells
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { col in
                            GameGridCell(
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
        }
        .cornerRadius(12)
    }

    private func gameGridLines(cellSize: CGFloat) -> some View {
        ZStack {
            // Vertical lines (excluding borders)
            ForEach(1..<3, id: \.self) { index in
                Rectangle()
                    .fill(gridBorderColor)
                    .frame(width: 2.5, height: cellSize * 3)
                    .offset(x: CGFloat(index) * cellSize - (cellSize * 1.5) + (cellSize / 2) - 1.25)
            }

            // Horizontal lines (excluding borders)
            ForEach(1..<3, id: \.self) { index in
                Rectangle()
                    .fill(gridBorderColor)
                    .frame(width: cellSize * 3, height: 2.5)
                    .offset(y: CGFloat(index) * cellSize - (cellSize * 1.5) + (cellSize / 2) - 1.25)
            }
        }
    }

    private var gridBorderColor: Color {
        switch gameLogic.gameMode {
        case .lunaMode:
            return Color.pink.opacity(0.6)
        case .unbeatableMode:
            return Color.pink.opacity(0.6) // Ahora usa el mismo color que Luna Mode
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
            return "new_game".localized
        case .unbeatableMode:
            return "new_game".localized
        case .infinityLevel:
            return "new_game".localized + " ∞"
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
                return .white // Cambio a blanco para mejor contraste
            } else if icon == "×" {
                return .white // Cambio a blanco para mejor contraste
            }
        }
        return .white // Color por defecto
    }
}

// MARK: - Game Grid Cell Component

struct GameGridCell: View {
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
                return Color.pink // Usa color rosa para mejor visibilidad
            } else if emoji == "×" {
                return Color.purple // Usa color púrpura para mejor visibilidad
            }
        }
        return Color.primary
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
