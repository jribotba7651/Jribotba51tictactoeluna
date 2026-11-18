import SwiftUI
import Foundation
import GoogleMobileAds
import UIKit

// MARK: - AdManager is defined in MenuView.swift

// BannerAdView is defined in MenuView.swift

struct GameView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared
    @ObservedObject private var interstitialAdManager = AdManager.shared
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
                        
                        Text("--- EDITANDO GAMEVIEW.SWIFT ---")
                            .foregroundColor(.yellow)
                            .font(.caption)

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
            print("🔍 GameView onAppear - PurchaseManager.shared.hasRemovedAds: \(PurchaseManager.shared.hasRemovedAds)")
        }
        .onChange(of: gameLogic.isGameOver) { oldValue, newValue in
            // Solo procesar cuando el juego cambia de false a true (juego terminado)
            guard !oldValue && newValue else { return }
            
            if gameLogic.gameMode == .lunaMode {
                print("🎊 CONFETTI TRIGGERED: Luna Mode End!")
                triggerMagicalEffect()
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                    print("🎊 CONFETTI STOPPED")
                }
            }
            
            triggerWinHaptic()

            // El contador de juegos y anuncios intersticiales se maneja en GameLogic.swift
            print("🎮 Game finished in GameView - GameLogic handles ad logic")
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
            return LinearGradient.lunaMode
        case .memoryMatch:
            return LinearGradient(colors: [Color.green.opacity(0.4), Color.teal.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    Text("Menú")
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
            return "🌙 Modo Luna"
        case .unbeatableMode:
            return "🤖 Modo Invencible"
        case .infinityLevel:
            return "∞ Infinity Level"
        case .memoryMatch:
            return "🧠 Memoria Boricua"
        }
    }

    // MARK: - Advertisement Section
    private var advertisementSection: some View {
        let hasRemovedAds = PurchaseManager.shared.hasRemovedAds

        return Group {
            // Mostrar banner en TODOS los modos de juego (lunaMode, unbeatableMode, memoryMatch)
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
                    BannerAdView(adUnitID: AdManager.bannerAdUnitID)
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
        if gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .unbeatableMode {
            return AnyShapeStyle(.ultraThinMaterial)
        } else {
            return AnyShapeStyle(Color.white.opacity(0.2))
        }
    }

    // MARK: - Game Board
    private func gameBoard(for geometry: GeometryProxy) -> some View {
        let boardSize: CGFloat = min(geometry.size.width - 40, 350)
        let cellSize: CGFloat = boardSize / 3
        let isTransparentGrid = gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel || gameLogic.gameMode == .unbeatableMode

        return ZStack {
            // No background for transparent grid modes
            if !isTransparentGrid {
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: boardSize, height: boardSize)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .cornerRadius(12)
            }

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
        .frame(width: boardSize, height: boardSize)
    }

    private func gameGridLines(cellSize: CGFloat) -> some View {
        let color = gridBorderColor
        let isTransparentGrid = gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .infinityLevel || gameLogic.gameMode == .unbeatableMode

        return ZStack {
            // Líneas Verticales (con glow para todos los modos transparentes)
            ForEach([-0.5, 0.5], id: \.self) { offset in
                Rectangle()
                    .fill(color)
                    .frame(width: 3.5, height: cellSize * 3) // Un poco más gruesas para exquisitez
                    .offset(x: offset * cellSize)
                    .shadow(color: isTransparentGrid ? color.opacity(0.8) : .clear, radius: 6)
            }

            // Líneas Horizontales (con glow para todos los modos transparentes)
            ForEach([-0.5, 0.5], id: \.self) { offset in
                Rectangle()
                    .fill(color)
                    .frame(width: cellSize * 3, height: 3.5) // Un poco más gruesas para exquisitez
                    .offset(y: offset * cellSize)
                    .shadow(color: isTransparentGrid ? color.opacity(0.8) : .clear, radius: 6)
            }
        }
    }

    private var gridBorderColor: Color {
        if gameLogic.gameMode == .lunaMode || gameLogic.gameMode == .unbeatableMode {
            return Color.white
        } else {
            return Color.pink.opacity(0.6)
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
        case .memoryMatch:
            return "🧠"
        }
    }

    private var newGameButtonText: String {
        switch gameLogic.gameMode {
        case .lunaMode:
            return "Nueva Partida"
        case .unbeatableMode:
            return "Nueva Partida"
        case .infinityLevel:
            return "Nueva Partida ∞"
        case .memoryMatch:
            return "Nueva Memoria"
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
        case .memoryMatch:
            return LinearGradient(colors: [Color.green, Color.teal], startPoint: .leading, endPoint: .trailing)
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
    @State private var bounceEffect = false

    var body: some View {
        Button(action: {
            triggerHaptic()
            triggerBounceEffect()
            action()
        }) {
            ZStack {
                // NO mostrar ningún fondo para Unbeatable Mode - completamente transparente
                // Los otros modos pueden tener fondos si es necesario en el futuro
                if gameMode != .unbeatableMode {
                    // Fondos solo para otros modos (si se agregan en el futuro)
                    if !emoji.isEmpty {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundForSymbol)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        strokeColorForSymbol,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: shadowColorForSymbol, radius: 8)
                    }
                }

                // Texto del símbolo con estilo mejorado
                Text(emoji)
                    .font(.system(size: cellSize * 0.5, weight: .black, design: .rounded))
                    .foregroundStyle(symbolGradient)
                    .shadow(color: shadowColorForSymbol.opacity(0.8), radius: 3)
                    .scaleEffect(bounceEffect ? 1.2 : 1.0)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .frame(width: cellSize - 6, height: cellSize - 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private var backgroundForSymbol: LinearGradient {
        if emoji == "○" {
            return LinearGradient(
                colors: [.pink.opacity(0.8), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if emoji == "×" {
            return LinearGradient(
                colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
    }

    private var symbolGradient: LinearGradient {
        if emoji == "○" {
            return LinearGradient(
                colors: [.white, .yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if emoji == "×" {
            return LinearGradient(
                colors: [.white, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom)
    }

    private var strokeColorForSymbol: Color {
        if emoji == "○" {
            return .pink.opacity(0.8)
        } else if emoji == "×" {
            return .blue.opacity(0.8)
        }
        return .clear
    }

    private var shadowColorForSymbol: Color {
        if emoji == "○" {
            return .pink
        } else if emoji == "×" {
            return .blue
        }
        return .clear
    }

    private func triggerBounceEffect() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            bounceEffect = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceEffect = false
            }
        }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
}

// MARK: - Preview
#Preview {
    GameView(gameLogic: GameLogic())
}
