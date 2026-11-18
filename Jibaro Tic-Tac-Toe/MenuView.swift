import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - Ad Utilities (Direct Injection)

class AdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdManager()

    @Published var isLoading = false
    @Published var isReady = false

    private var interstitialAd: InterstitialAd?
    private var presentationAttempted = false
    // Usar anuncios de test en DEBUG, producción en RELEASE
    private let adUnitID: String = {
        #if DEBUG
        return "ca-app-pub-3940256099942544/4411468910" // Test Interstitial ID
        #else
        return "ca-app-pub-3258994800717071/8816859712" // Production Interstitial ID
        #endif
    }()

    static let bannerAdUnitID: String = {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716" // Test Banner ID
        #else
        return "ca-app-pub-3258994800717071/5955178067" // Production Banner ID
        #endif
    }()

    private let purchaseManager = PurchaseManager.shared
    private let gameFrequency = 10
    private var retryAttempt = 0.0
    private let maxRetryDelay: TimeInterval = 64.0

    override init() {
        super.init()
        loadInterstitialAd()
    }

    func loadInterstitialAd() {
        if PurchaseManager.shared.hasRemovedAds {
            print("🚫 InterstitialAd: Ads removed, not loading")
            return
        }
        print("🔄 InterstitialAd: Starting to load ad with ID: \(adUnitID)")
        isLoading = true
        isReady = false
        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    print("❌ InterstitialAd: Load failed with error: \(error.localizedDescription)")
                    self?.retryLoading()
                    return
                }
                print("✅ InterstitialAd: Successfully loaded ad")
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isReady = true
                print("🎯 InterstitialAd: Ready state set to true")
            }
        }
    }
    
    private func retryLoading() {
        retryAttempt += 1
        let delay = min(pow(2.0, retryAttempt), maxRetryDelay)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.loadInterstitialAd()
        }
    }

    func presentInterstitialAd() {
        print("🎬 InterstitialAd: presentInterstitialAd() called")

        if PurchaseManager.shared.hasRemovedAds {
            print("🚫 InterstitialAd: Ads removed, not showing")
            return
        }

        print("🔍 InterstitialAd: isReady = \(isReady), isLoading = \(isLoading)")

        guard isReady else {
            print("❌ InterstitialAd: Not ready, loading new ad")
            loadInterstitialAd()
            return
        }

        guard let interstitialAd = interstitialAd else {
            print("❌ InterstitialAd: No ad instance available")
            loadInterstitialAd()
            return
        }

        print("🎯 InterstitialAd: Ad instance exists, getting root view controller...")

        // Try multiple approaches to get the right view controller
        var presentingVC: UIViewController?

        // Method 1: Try to get the currently presented view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            // Find the topmost presented view controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            presentingVC = topVC
            print("🎯 InterstitialAd: Found topmost VC: \(type(of: topVC))")
        }

        guard let finalVC = presentingVC else {
            print("❌ InterstitialAd: Could not get any view controller")
            return
        }

        print("🎬 InterstitialAd: Attempting to present ad from \(type(of: finalVC))")

        // Ensure we're on the main thread and wait for any ongoing animations to complete
        DispatchQueue.main.async {
            // Reset presentation tracking
            self.presentationAttempted = true

            // Double-check that the view controller is ready
            if finalVC.view.window != nil && !finalVC.isBeingPresented && !finalVC.isBeingDismissed {
                print("🎬 InterstitialAd: View controller is ready, presenting now")
                interstitialAd.present(from: finalVC)
                print("🎬 InterstitialAd: Present method called successfully")

                // Set a timeout to detect if presentation failed silently
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if self.presentationAttempted {
                        print("⚠️ InterstitialAd: 3 seconds passed and no delegate method was called - ad may have failed silently")
                        print("⚠️ InterstitialAd: This usually indicates a view controller hierarchy issue")
                        // Load a new ad for next time
                        self.loadInterstitialAd()
                    }
                }
            } else {
                print("❌ InterstitialAd: View controller not ready - window: \(finalVC.view.window != nil), isBeingPresented: \(finalVC.isBeingPresented), isBeingDismissed: \(finalVC.isBeingDismissed)")

                // Try again with root controller as fallback
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    print("🔄 InterstitialAd: Falling back to root view controller")
                    interstitialAd.present(from: rootVC)

                    // Also set timeout for fallback
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if self.presentationAttempted {
                            print("⚠️ InterstitialAd: Fallback also failed silently")
                            self.loadInterstitialAd()
                        }
                    }
                }
            }
        }
    }

    func shouldShowAdAfterGames(_ gamesCount: Int) -> Bool {
        if PurchaseManager.shared.hasRemovedAds { return false }
        if !isReady { return false }
        return gamesCount > 0 && gamesCount % gameFrequency == 0
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ InterstitialAd: Ad dismissed, loading new ad")
        presentationAttempted = false
        loadInterstitialAd()
    }

    func adDidFailToPresentFullScreenContent(_ ad: FullScreenPresentingAd, withError error: Error) {
        print("❌ InterstitialAd: Failed to present with error: \(error.localizedDescription)")
        presentationAttempted = false
        loadInterstitialAd()
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("🎬 InterstitialAd: Will present full screen content")
        presentationAttempted = false
    }

    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 InterstitialAd: Did record impression")
    }
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> UIView {
        if PurchaseManager.shared.hasRemovedAds {
            print("🚫 BannerAdView: Ads removed, returning empty view")
            return UIView()
        }

        print("🎯 BannerAdView: Creating banner with adUnitID: \(adUnitID)")
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID

        // Configurar el rootViewController
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                bannerView.rootViewController = rootViewController
                print("🎯 BannerAdView: Root view controller set")
            } else {
                print("❌ BannerAdView: Could not get root view controller")
            }
        }

        // Cargar el anuncio
        let request = Request()
        bannerView.load(request)
        print("🎯 BannerAdView: Ad request sent")

        // Añadir delegate para debugging
        bannerView.delegate = context.coordinator

        return bannerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> BannerAdCoordinator {
        BannerAdCoordinator()
    }
}

class BannerAdCoordinator: NSObject, BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("✅ Banner ad loaded successfully")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Banner ad failed to load: \(error.localizedDescription)")
    }
}

struct MenuView: View {
    @StateObject private var gameLogic = GameLogic()
    @ObservedObject private var adManager = AdManager.shared

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
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .playing && gameLogic.gameMode != .memoryMatch)) {
            GameView(gameLogic: gameLogic)
        }
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .settings)) {
            SettingsView(gameLogic: gameLogic)
        }
        .fullScreenCover(isPresented: .constant(gameLogic.gameState == .playing && gameLogic.gameMode == .memoryMatch)) {
            MemoryMatchView {
                gameLogic.gameState = .menu
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 15) {
            HStack {
                Spacer()

                // Botón de configuración mejorado para niños
                Button(action: {
                    gameLogic.showSettings()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 55, height: 55)
                            .shadow(color: .purple.opacity(0.5), radius: 8)

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 55, height: 55)

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }
                .scaleEffect(1.0)
                .buttonStyle(PlainButtonStyle())
            }

            // Título principal MEJORADO PARA NIÑOS
            VStack(spacing: 10) {
                HStack(spacing: 15) {
                    Text("🌙")
                        .font(.system(size: 50))
                        .scaleEffect(1.2)

                    VStack {
                        Text("LUNA")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Tic-Tac-Toe")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 3)
                    }

                    Text("🎉")
                        .font(.system(size: 50))
                        .scaleEffect(1.2)
                }

                // Subtítulo divertido para niños
                Text("¡Juega y Diviértete!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.6))
                    )
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
                            print("🔍 Menu banner placeholder appeared, hasRemovedAds: \(PurchaseManager.shared.hasRemovedAds)")
                        }

                    // Banner ad on top
                    BannerAdView(adUnitID: AdManager.bannerAdUnitID)
                        .frame(height: 60)
                        .id("menu-banner") // ID único para forzar recreación si es necesario
                }
                .frame(height: 60)
                .cornerRadius(15)
                .onAppear {
                    print("🔍 Menu ad section appeared")
                }
            } else {
                // Espacio mínimo cuando los anuncios están removidos
                Color.clear.frame(height: 8)
                    .onAppear {
                        print("🚫 Menu ads removed")
                    }
            }
        }
    }

    // MARK: - Game Modes Section
    private var gameModesSection: some View {
        VStack(spacing: 20) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                GameModeCard(mode: mode) {
                    if mode == .memoryMatch {
                        gameLogic.gameMode = .memoryMatch
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
    @State private var isPressed = false

    var body: some View {
        Button(action: mode == .infinityLevel ? {} : action) {
            VStack(spacing: 20) {
                // Header con emoji grande y divertido
                HStack {
                    Text(emojiForMode(mode))
                        .font(.system(size: 50))
                        .scaleEffect(isPressed ? 0.8 : 1.0)

                    Spacer()

                    // Flecha más divertida
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 5)
                }

                // Títulos con estilo infantil
                VStack(alignment: .leading, spacing: 10) {
                    Text(mode.title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2)

                    Text(mode.subtitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Características con estilo más divertido
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(mode.features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 16))
                                .shadow(color: .orange.opacity(0.5), radius: 2)

                            Text(feature)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)

                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(25)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    // Fondo con gradiente
                    RoundedRectangle(cornerRadius: 25)
                        .fill(gradientForMode(mode))

                    // Imagen de fondo para Boricua Memory
                    if mode == .memoryMatch {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.clear)
                            .overlay(
                                Image("coqui")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(0.15)
                                    .clipped()
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }

                    // Overlay brillante para efecto infantil
                    RoundedRectangle(cornerRadius: 25)
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

                    // Borde brillante
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .overlay(
                // Overlay de "Coming Soon" para infinityLevel
                mode == .infinityLevel ?
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.7))

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)

                        Text("PRÓXIMAMENTE")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Coming Soon")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } : nil
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            .shadow(color: colorForMode(mode).opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if mode != .infinityLevel {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
        .drawingGroup()
    }

    private func emojiForMode(_ mode: GameMode) -> String {
        switch mode {
        case .lunaMode:
            return "🌙"
        case .unbeatableMode:
            return "🔥"
        case .infinityLevel:
            return "∞"
        case .memoryMatch:
            return "🧠"
        }
    }

    private func colorForMode(_ mode: GameMode) -> Color {
        switch mode {
        case .lunaMode:
            return .purple
        case .unbeatableMode:
            return .red
        case .infinityLevel:
            return .orange
        case .memoryMatch:
            return .green
        }
    }

    private func gradientForMode(_ mode: GameMode) -> LinearGradient {
        switch mode {
        case .lunaMode:
            return LinearGradient.menuCardLuna
        case .unbeatableMode:
            return LinearGradient.menuCardUnbeatable
        case .infinityLevel:
            return LinearGradient.menuCardInfinity
        case .memoryMatch:
            return LinearGradient.menuCardMemory
        }
    }
}


// MARK: - Preview
#Preview {
    MenuView()
}