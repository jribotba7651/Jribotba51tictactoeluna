import SwiftUI
import AVFoundation

// MARK: - Memory Match Card Model
struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let displayName: String
    let pairId: Int
    var isFlipped: Bool = false
    var isMatched: Bool = false
    var isAnimating: Bool = false

    static func == (lhs: MemoryCard, rhs: MemoryCard) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Game Level Enum
enum MemoryGameLevel: Int, CaseIterable {
    case easy = 12   // 6 pares (12 cartas) - 3x4 grid
    case medium = 16 // 8 pares (16 cartas) - 4x4 grid
    case hard = 20   // 10 pares (20 cartas) - 4x5 grid

    var displayName: String {
        switch self {
        case .easy: return "Fácil"
        case .medium: return "Medio"
        case .hard: return "Difícil"
        }
    }

    var pairCount: Int {
        return self.rawValue / 2
    }

    var gridColumns: Int {
        switch self {
        case .easy: return 3    // 3x4
        case .medium: return 4  // 4x4
        case .hard: return 4    // 4x5
        }
    }

    var gridRows: Int {
        switch self {
        case .easy: return 4
        case .medium: return 4
        case .hard: return 5
        }
    }
}

// MARK: - Memory Match Game Logic
class MemoryMatchGameLogic: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var flippedCards: [MemoryCard] = []
    @Published var score: Int = 0
    @Published var moves: Int = 0
    @Published var gameCompleted: Bool = false
    @Published var showingCelebration: Bool = false
    @Published var timeElapsed: TimeInterval = 0
    @Published var currentLevel: MemoryGameLevel = .easy
    @Published var showingLevelSelection: Bool = true
    @Published var showingCardDesignSelection: Bool = false
    @Published var selectedCardBack: String = "card_back_bandera"

    private var gameTimer: Timer?
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // Imágenes auténticas boricuas para niños
    private let boricuaImages: [(imageName: String, displayName: String)] = [
        ("coqui", "Coquí"),
        ("cuatro", "Cuatro"),
        ("flamboyan", "Flamboyán"),
        ("garita", "Garita"),
        ("hamaca", "Hamaca"),
        ("palma", "Palma"),
        ("mofongo", "Mofongo"),
        ("piragua", "Piragua"),
        ("bomba", "Bomba"),
        ("vejigante", "Vejigante")
    ]

    init() {
        // No setupGame() aquí, esperamos selección de nivel
    }

    func startGame(level: MemoryGameLevel) {
        currentLevel = level
        showingLevelSelection = false
        showingCardDesignSelection = true
    }

    func startGameWithDesign(cardBack: String) {
        selectedCardBack = cardBack
        showingCardDesignSelection = false
        setupGame()
    }

    func setupGame() {
        createCards()
        shuffleCards()
        startTimer()
        gameCompleted = false
        showingCelebration = false
        score = 0
        moves = 0
        timeElapsed = 0
    }

    private func createCards() {
        cards = []

        // Obtener número de pares necesarios para el nivel actual
        let pairsNeeded = currentLevel.pairCount
        print("🃏 Creating cards for \(currentLevel.displayName) level: need \(pairsNeeded) pairs")

        // Usar las imágenes disponibles, repitiendo si es necesario
        let availableImages = Array(boricuaImages.prefix(min(pairsNeeded, boricuaImages.count)))
        print("🖼️ Available images: \(availableImages.map { $0.imageName })")

        // Crear pares de cartas
        for (index, imageInfo) in availableImages.enumerated() {
            // Primera carta del par
            let card1 = MemoryCard(imageName: imageInfo.imageName, displayName: imageInfo.displayName, pairId: index)
            // Segunda carta del par
            let card2 = MemoryCard(imageName: imageInfo.imageName, displayName: imageInfo.displayName, pairId: index)

            cards.append(card1)
            cards.append(card2)
            print("🃏 Created pair \(index): \(imageInfo.imageName) (\(imageInfo.displayName))")
        }
        print("🎲 Total cards created: \(cards.count)")
    }

    private func shuffleCards() {
        cards.shuffle()
    }

    private func startTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.timeElapsed += 1
            }
        }
    }

    private func stopTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    func cardTapped(_ card: MemoryCard) {
        guard !card.isMatched && !card.isFlipped && flippedCards.count < 2 else { return }

        impactFeedback.impactOccurred()

        if let index = cards.firstIndex(of: card) {
            cards[index].isFlipped = true
            cards[index].isAnimating = true
            flippedCards.append(cards[index])

            // Animación de volteo
            withAnimation(.easeInOut(duration: 0.3)) {
                cards[index].isAnimating = false
            }

            if flippedCards.count == 2 {
                moves += 1
                checkForMatch()
            }
        }
    }

    private func checkForMatch() {
        let card1 = flippedCards[0]
        let card2 = flippedCards[1]

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if card1.pairId == card2.pairId {
                // ¡Es una pareja!
                self.handleMatch()
            } else {
                // No es pareja
                self.handleMismatch()
            }

            self.flippedCards.removeAll()
            self.checkGameCompletion()
        }
    }

    private func handleMatch() {
        notificationFeedback.notificationOccurred(.success)

        for flippedCard in flippedCards {
            if let index = cards.firstIndex(of: flippedCard) {
                cards[index].isMatched = true

                // Animación de éxito
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    cards[index].isAnimating = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.cards[index].isAnimating = false
                }
            }
        }

        score += 10 // Puntos por pareja encontrada
    }

    private func handleMismatch() {
        notificationFeedback.notificationOccurred(.error)

        for flippedCard in flippedCards {
            if let index = cards.firstIndex(of: flippedCard) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    cards[index].isFlipped = false
                }
            }
        }
    }

    private func checkGameCompletion() {
        if cards.allSatisfy({ $0.isMatched }) {
            gameCompleted = true
            showingCelebration = true
            stopTimer()

            // Bonus por completar rápido
            let timeBonus = max(0, 300 - Int(timeElapsed)) // Bonus si completa en menos de 5 minutos
            score += timeBonus

            // Confetti celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.notificationFeedback.notificationOccurred(.success)
            }
        }
    }

    func resetGame() {
        stopTimer()
        setupGame()
    }

    func backToLevelSelection() {
        stopTimer()
        showingLevelSelection = true
        showingCardDesignSelection = false
        cards = []
        score = 0
        moves = 0
        timeElapsed = 0
        gameCompleted = false
        showingCelebration = false
    }

    deinit {
        stopTimer()
    }
}

// MARK: - Memory Match View
struct MemoryMatchView: View {
    @ObservedObject var gameLogic = MemoryMatchGameLogic()
    let onBack: () -> Void

    // Grid dinámico basado en el nivel actual
    private var dynamicGridColumns: [GridItem] {
        let columns = gameLogic.currentLevel.gridColumns
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }

    var body: some View {
        ZStack {
            // Fondo con gradiente boricua
            LinearGradient(
                colors: [
                    Color.green.opacity(0.4),
                    Color.teal.opacity(0.3),
                    Color.blue.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if gameLogic.showingLevelSelection {
                levelSelectionView
            } else if gameLogic.showingCardDesignSelection {
                cardDesignSelectionView
            } else {
                GeometryReader { geometry in
                    VStack(spacing: 12) {
                        headerSection
                        statsSection
                        gameGrid(geometry: geometry)
                        controlButtons
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 0)
                }
            }

            // Overlay de celebración
            if gameLogic.showingCelebration {
                celebrationOverlay
            }
        }
        .onDisappear {
            // Limpiar cuando salga de la vista
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("🧠")
                .font(.system(size: 24))

            VStack(spacing: 2) {
                Text(localizedString("memory_boricua"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(localizedString("find_pairs"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.8))
                    )
            }

            Text("🌺")
                .font(.system(size: 24))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            // Puntuación
            StatCard(
                title: localizedString("score"),
                value: "\(gameLogic.score)",
                icon: "⭐",
                color: .yellow
            )

            // Movimientos
            StatCard(
                title: localizedString("moves"),
                value: "\(gameLogic.moves)",
                icon: "🎯",
                color: .orange
            )

            // Tiempo
            StatCard(
                title: localizedString("time"),
                value: formatTime(gameLogic.timeElapsed),
                icon: "⏱️",
                color: .purple
            )
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Game Grid
    private func gameGrid(geometry: GeometryProxy) -> some View {
        let level = gameLogic.currentLevel
        let columns = level.gridColumns
        let rows = level.gridRows

        // Calcular espacio disponible para el grid
        let headerHeight: CGFloat = 40
        let statsHeight: CGFloat = 80
        let controlsHeight: CGFloat = 100
        let availableHeight = geometry.size.height - headerHeight - statsHeight - controlsHeight - 80 // padding y spacing

        // Calcular tamaño de carta dinámicamente
        let containerHorizontalPadding: CGFloat = 16 // padding del LazyVGrid container
        let screenHorizontalPadding: CGFloat = 32 // padding de los lados de la pantalla (16 cada lado)
        let cardSpacing: CGFloat = 8
        let totalHorizontalSpacing = CGFloat(columns - 1) * cardSpacing
        let totalHorizontalPadding = screenHorizontalPadding + (containerHorizontalPadding * 2)
        let availableWidth = geometry.size.width - totalHorizontalPadding - totalHorizontalSpacing
        let cardWidth = availableWidth / CGFloat(columns)

        let totalVerticalSpacing = CGFloat(rows - 1) * cardSpacing
        let availableGridHeight = availableHeight - 32 // padding del background
        let cardHeight = (availableGridHeight - totalVerticalSpacing) / CGFloat(rows)

        // Usar el menor entre cardWidth y cardHeight para mantener proporción
        let finalCardSize = min(cardWidth, cardHeight)

        let gridColumns = Array(repeating: GridItem(.fixed(finalCardSize), spacing: cardSpacing), count: columns)

        return LazyVGrid(columns: gridColumns, spacing: cardSpacing) {
            ForEach(gameLogic.cards) { card in
                MemoryCardView(card: card, size: finalCardSize, selectedCardBack: gameLogic.selectedCardBack) {
                    gameLogic.cardTapped(card)
                }
                .frame(width: finalCardSize, height: finalCardSize)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.25))
                .shadow(color: .teal.opacity(0.2), radius: 6)
        )
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 8) {
            // Botón Volver al Menú
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 16))
                    Text(localizedString("back"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.gray.opacity(0.8), .gray.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }

            // Botón Nueva Partida
            Button(action: gameLogic.resetGame) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 16))
                    Text(localizedString("new_game"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.green.opacity(0.8), .teal.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }

            // Cambiar Nivel
            Button(action: gameLogic.backToLevelSelection) {
                HStack(spacing: 4) {
                    Image(systemName: "level.fill")
                        .font(.system(size: 16))
                    Text("Nivel: \(gameLogic.currentLevel.displayName)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .indigo.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Celebration Overlay
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Título de celebración
                VStack(spacing: 10) {
                    Text("🎉")
                        .font(.system(size: 80))
                        .scaleEffect(gameLogic.showingCelebration ? 1.2 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: gameLogic.showingCelebration)

                    Text(localizedString("congratulations"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                        .multilineTextAlignment(.center)

                    Text(localizedString("all_pairs_found"))
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 15)
                )

                // Estadísticas finales
                VStack(spacing: 15) {
                    StatRow(label: localizedString("final_score"), value: "\(gameLogic.score) ⭐")
                    StatRow(label: localizedString("total_moves"), value: "\(gameLogic.moves) 🎯")
                    StatRow(label: localizedString("total_time"), value: formatTime(gameLogic.timeElapsed) + " ⏱️")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.9))
                )

                // Botones
                HStack(spacing: 15) {
                    Button(localizedString("play_again")) {
                        gameLogic.resetGame()
                    }
                    .buttonStyle(CelebrationButtonStyle(color: .pink, style: .filled))

                    Button(localizedString("back_to_menu")) {
                        onBack()
                    }
                    .buttonStyle(CelebrationButtonStyle(color: .purple, style: .outline))
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Functions
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func localizedString(_ key: String) -> String {
        let isSpanish = UserDefaults.standard.string(forKey: "AppLanguage") == "es"
        let translations: [String: String] = [
            "memory_boricua": isSpanish ? "Memoria Boricua" : "Boricua Memory",
            "find_pairs": isSpanish ? "¡Encuentra las parejas!" : "Find the pairs!",
            "score": isSpanish ? "Puntos" : "Score",
            "moves": isSpanish ? "Movidas" : "Moves",
            "time": isSpanish ? "Tiempo" : "Time",
            "back": isSpanish ? "Volver" : "Back",
            "new_game": isSpanish ? "Nueva Partida" : "New Game",
            "congratulations": isSpanish ? "¡Felicidades!" : "Congratulations!",
            "all_pairs_found": isSpanish ? "¡Encontraste todas las parejas!" : "You found all the pairs!",
            "final_score": isSpanish ? "Puntuación final" : "Final Score",
            "total_moves": isSpanish ? "Total de movidas" : "Total Moves",
            "total_time": isSpanish ? "Tiempo total" : "Total Time",
            "play_again": isSpanish ? "Jugar de nuevo" : "Play Again",
            "back_to_menu": isSpanish ? "Volver al menú" : "Back to Menu",
            "choose_card_design": isSpanish ? "Elige tu diseño de carta" : "Choose your card design",
            "bandera_design": isSpanish ? "Bandera Boricua" : "Boricua Flag",
            "tainos_design": isSpanish ? "Diseños Taínos" : "Taíno Designs"
        ]
        return translations[key] ?? key
    }

    // MARK: - Level Selection View
    private var levelSelectionView: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Text("🌺")
                    .font(.system(size: 60))
                    .scaleEffect(1.2)

                VStack(spacing: 8) {
                    Text("Memoria Boricua")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .teal, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .teal, radius: 3)

                    Text("¡Elige tu nivel de dificultad!")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.8))
                        )
                }
            }

            // Level Selection Cards
            VStack(spacing: 20) {
                ForEach(MemoryGameLevel.allCases, id: \.self) { level in
                    LevelSelectionCard(
                        level: level,
                        onSelect: { gameLogic.startGame(level: level) }
                    )
                }
            }

            // Back Button
            Button(action: onBack) {
                HStack {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title2)
                    Text("Volver al Menú")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.gray.opacity(0.8), .gray.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .gray.opacity(0.4), radius: 8)
            }
        }
        .padding()
    }

    // MARK: - Card Design Selection View
    private var cardDesignSelectionView: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 15) {
                Text("🎨")
                    .font(.system(size: 60))

                Text(localizedString("choose_card_design"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .teal, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
            }

            // Design Options
            HStack(spacing: 30) {
                // Bandera Design
                CardDesignButton(
                    imageName: "card_back_bandera",
                    title: localizedString("bandera_design"),
                    isSelected: gameLogic.selectedCardBack == "card_back_bandera"
                ) {
                    gameLogic.startGameWithDesign(cardBack: "card_back_bandera")
                }

                // Tainos Design
                CardDesignButton(
                    imageName: "card_back_tainos",
                    title: localizedString("tainos_design"),
                    isSelected: gameLogic.selectedCardBack == "card_back_tainos"
                ) {
                    gameLogic.startGameWithDesign(cardBack: "card_back_tainos")
                }
            }

            // Back Button
            Button(action: gameLogic.backToLevelSelection) {
                HStack {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.title2)
                    Text("Volver a Niveles")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.gray.opacity(0.8), .gray.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .gray.opacity(0.4), radius: 8)
            }
        }
        .padding()
    }
}

// MARK: - Card Design Button
struct CardDesignButton: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 15) {
                // Card Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 120, height: 160)
                        .shadow(color: .black.opacity(0.2), radius: 8)

                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .overlay(
                    // Selection indicator
                    isSelected ?
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .teal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        ) : nil
                )

                // Title
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .green : .primary)
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Memory Card View
struct MemoryCardView: View {
    let card: MemoryCard
    let size: CGFloat
    let selectedCardBack: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Fondo de la carta
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .stroke(cardBorderColor, lineWidth: max(2, size * 0.05))
                    )
                    .shadow(color: cardShadowColor, radius: card.isFlipped || card.isMatched ? 8 : 4)
                    .scaleEffect(card.isAnimating ? 1.1 : 1.0)
                    .rotation3DEffect(
                        .degrees(card.isFlipped || card.isMatched ? 0 : 180),
                        axis: (x: 0, y: 1, z: 0)
                    )

                // Contenido de la carta
                if card.isFlipped || card.isMatched {
                    // Cara frontal - imagen boricua
                    ZStack {
                        Image(card.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(size * 0.15)
                            .scaleEffect(card.isMatched ? 1.05 : 1.0)
                            .opacity(card.isMatched ? 0.9 : 1.0)
                            .onAppear {
                                print("🖼️ Loading image: \(card.imageName) for card with pairId: \(card.pairId)")
                            }

                        // Fallback text if image doesn't load
                        Text(card.displayName)
                            .font(.system(size: min(size * 0.2, 16), weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(0.0) // Invisible unless needed
                    }
                } else {
                    // Cara trasera - imagen seleccionada
                    Image(selectedCardBack)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
                        .opacity(0.9)
                }
            }
        }
        .disabled(card.isFlipped || card.isMatched)
        .animation(.easeInOut(duration: 0.6), value: card.isFlipped)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: card.isMatched)
        .animation(.easeInOut(duration: 0.3), value: card.isAnimating)
    }

    private var cardBackgroundColor: LinearGradient {
        if card.isMatched {
            return LinearGradient(
                colors: [.green.opacity(0.8), .teal.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if card.isFlipped {
            return LinearGradient(
                colors: [.white, .cyan.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var cardBorderColor: Color {
        if card.isMatched {
            return .green
        } else if card.isFlipped {
            return .cyan
        } else {
            return .blue.opacity(0.7)
        }
    }

    private var cardShadowColor: Color {
        if card.isMatched {
            return .green.opacity(0.6)
        } else if card.isFlipped {
            return .cyan.opacity(0.4)
        } else {
            return .blue.opacity(0.3)
        }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 16))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.8))
                .shadow(color: color.opacity(0.2), radius: 2)
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
        }
    }
}

struct CelebrationButtonStyle: ButtonStyle {
    let color: Color
    let style: ButtonStyleType

    enum ButtonStyleType {
        case filled, outline
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(style == .filled ? .white : color)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Group {
                    if style == .filled {
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                style == .outline ?
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    ) : nil
            )
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.4), radius: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Level Selection Card
struct LevelSelectionCard: View {
    let level: MemoryGameLevel
    let onSelect: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 20) {
                // Icon and Level Info
                VStack(spacing: 8) {
                    Text(levelEmoji)
                        .font(.system(size: 40))
                        .scaleEffect(isPressed ? 0.9 : 1.0)

                    Text(level.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Level Details
                VStack(alignment: .trailing, spacing: 6) {
                    HStack {
                        Text("\(level.rawValue)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("cartas")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text("Grid \(level.gridColumns)x\(level.gridRows)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )

                    Text("\(level.pairCount) pares")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Arrow
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 5)
            }
            .padding(20)
            .background(
                ZStack {
                    // Background gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(levelGradient)

                    // Overlay for shine effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear,
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: levelColor.opacity(0.4), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    private var levelEmoji: String {
        switch level {
        case .easy: return "🥥"
        case .medium: return "🌴"
        case .hard: return "🦜"
        }
    }

    private var levelColor: Color {
        switch level {
        case .easy: return .green
        case .medium: return .teal
        case .hard: return .blue
        }
    }

    private var levelGradient: LinearGradient {
        switch level {
        case .easy:
            return LinearGradient(
                colors: [.green.opacity(0.8), .teal.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .medium:
            return LinearGradient(
                colors: [.teal.opacity(0.8), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .hard:
            return LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}