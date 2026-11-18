import SwiftUI
import Foundation

// MARK: - Temporary Inline Definitions (to fix compilation)
class LocalizationManagerTemp: ObservableObject {
    static let shared = LocalizationManagerTemp()
    @Published var currentLanguage = "en"

    func localizedString(for key: String) -> String {
        let isSpanish = UserDefaults.standard.string(forKey: "AppLanguage") == "es"
        let strings: [String: String] = [
            "settings": isSpanish ? "Configuración" : "Settings",
            "done": isSpanish ? "Listo" : "Done",
            "player_1": isSpanish ? "Jugador 1" : "Player 1",
            "player_2": isSpanish ? "Jugador 2" : "Player 2",
            "language": isSpanish ? "Idioma:" : "Language:",
            "reset_scores": isSpanish ? "Reiniciar Puntuaciones" : "Reset Scores"
        ]
        return strings[key] ?? key
    }
}

class DiagnosticsManagerTemp: ObservableObject {
    static let shared = DiagnosticsManagerTemp()
    @Published var logs: [String] = []
    @Published var adMobStatus = "OK"
    @Published var iapStatus = "OK"

    func log(_ message: String, type: String = "info") {
        print("[\(type)] \(message)")
    }

    func clearLogs() {
        logs.removeAll()
    }
}

struct SettingsView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared
    @ObservedObject private var localization = LocalizationManagerTemp.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con gradiente de Luna Mode
                LinearGradient.lunaMode
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 20)

                        // Configuración del Jugador 1
                        PlayerConfigurationSection(
                            title: "Jugador 1",
                            playerConfig: $dataManager.player1Config,
                            borderColor: .pink,
                            titleColor: .playerTitlePink
                        )

                        // Configuración del Jugador 2
                        PlayerConfigurationSection(
                            title: "Jugador 2",
                            playerConfig: $dataManager.player2Config,
                            borderColor: .blue,
                            titleColor: .playerTitleBlue
                        )

                        // Configuración del juego
                        GameConfigurationSection()

                        // Compras In-App
                        PurchaseSection()

                        // Diagnóstico (Solo visible para depuración)
                        DiagnosticsSection()

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationTitle("Configuración")
        .overlay(
            // Header personalizado
            VStack {
                HStack {
                    // Botón de regresar
                    Button(action: {
                        gameLogic.backToMenu()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Menú")
                                .font(.headline)
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

                    // Título
                    Text("Configuración")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    // Botón Listo (invisible para balancear)
                    Button(action: {
                        gameLogic.backToMenu()
                    }) {
                        Text("Listo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .buttonAnimation()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()
            }
        )
    }
}

// MARK: - Player Configuration Section
struct PlayerConfigurationSection: View {
    let title: String
    @Binding var playerConfig: PlayerConfig
    let borderColor: Color
    let titleColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Título de la sección
            Text(title)
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textShadow()

            VStack(spacing: 20) {
                // Campo de nombre
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre:")
                        .font(.headline)
                        .foregroundColor(.black)

                    TextField("Nombre del jugador", text: $playerConfig.name)
                        .font(.title3)
                        .foregroundColor(.black)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(borderColor.opacity(0.6), lineWidth: 2)
                                )
                        )
                }

                // Selector de emoji
                VStack(alignment: .leading, spacing: 15) {
                    Text("Emoji:")
                        .font(.headline)
                        .foregroundColor(.black)

                    EmojiSelectionGrid(
                        selectedEmoji: $playerConfig.emoji,
                        borderColor: borderColor
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.8))
            )
            .roundedBorder(color: borderColor.opacity(0.5))
            .cardShadow()
        }
    }
}

// MARK: - Emoji Selection Grid
struct EmojiSelectionGrid: View {
    @Binding var selectedEmoji: String
    let borderColor: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(EmojiCollection.availableEmojis, id: \.self) { emoji in
                Button(action: {
                    selectedEmoji = emoji
                }) {
                    Text(emoji)
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedEmoji == emoji ? borderColor : Color.gray.opacity(0.3),
                                            lineWidth: selectedEmoji == emoji ? 3 : 1
                                        )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(selectedEmoji == emoji ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: selectedEmoji)
            }
        }
    }
}

// MARK: - Game Configuration Section
struct GameConfigurationSection: View {
    @StateObject private var dataManager = DataManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Título de la sección
            Text("Configuración del Juego")
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textShadow()

            VStack(spacing: 20) {
                // Toggle de sonido
                HStack {
                    Text("Sonidos del juego:")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    Toggle("", isOn: $dataManager.soundEnabled)
                        .scaleEffect(0.8)
                }

                Divider()

                // Language selector
                LanguageSelectorView()

                Divider()

                // Botón de reiniciar puntuaciones
                Button(action: {
                    dataManager.resetAllScores()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)

                        Text("Reiniciar Puntuaciones")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.pink.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonAnimation()
                .cardShadow()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.8))
            )
            .roundedBorder(color: Color.gray.opacity(0.3))
            .cardShadow()
        }
    }
}

// MARK: - Purchase Section
struct PurchaseSection: View {
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Compras")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textShadow()

            if purchaseManager.hasRemovedAds {
                // Usuario ya compró la remoción de anuncios
                VStack(spacing: 15) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("Anuncios Removidos")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }

                    Text("¡Gracias por tu compra! Disfruta del juego sin anuncios.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Restaurar Compras") {
                        purchaseManager.restorePurchases()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .disabled(purchaseManager.isLoading)
                }
            } else {
                // Usuario no ha comprado la remoción de anuncios
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Remover Anuncios")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Disfruta del juego sin interrupciones")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        if let product = purchaseManager.getRemoveAdsProduct() {
                            Text(product.localizedPrice ?? "$1.99")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text("$1.99")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }

                    HStack(spacing: 15) {
                        Button("Comprar") {
                            purchaseManager.purchaseRemoveAds()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.mint]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .disabled(purchaseManager.isLoading)

                        Button("Restaurar") {
                            purchaseManager.restorePurchases()
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .disabled(purchaseManager.isLoading)
                    }

                    if purchaseManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Procesando...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.8))
        )
        .roundedBorder(color: Color.purple.opacity(0.3))
        .cardShadow()
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("PurchaseCompleted"))) { _ in
            alertTitle = "¡Compra Exitosa!"
            alertMessage = "Los anuncios han sido removidos. ¡Gracias por tu compra!"
            showingAlert = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("PurchaseFailed"))) { notification in
            alertTitle = "Error en la Compra"
            alertMessage = notification.object as? String ?? "Hubo un problema con la compra. Inténtalo de nuevo."
            showingAlert = true
        }
    }
}

// MARK: - Language Selector View
struct LanguageSelectorView: View {
    @StateObject private var localization = LocalizationManagerTemp.shared

    var body: some View {
        HStack {
            Text(localization.localizedString(for: "language"))
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            Spacer()

            HStack {
                Text("🇪🇸 Español")
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
    }

// MARK: - Preview
#Preview {
    SettingsView(gameLogic: GameLogic())
}

// MARK: - Diagnostics Section
struct DiagnosticsSection: View {
    @StateObject private var diagnostics = DiagnosticsManagerTemp.shared
    @State private var isExpanded = false

    var body: some View {
        // Simplified diagnostics section for compilation
        VStack {
            Text("🩺 Diagnósticos")
                .font(.headline)
                .foregroundColor(.white)

            Text("Estado: OK")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.blue.opacity(0.8))
        .cornerRadius(15)
    }
}

struct StatusCard: View {
    let title: String
    let status: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(status)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}