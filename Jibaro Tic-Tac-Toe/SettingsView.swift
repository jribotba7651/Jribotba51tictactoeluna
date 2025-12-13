import SwiftUI

struct SettingsView: View {
    @ObservedObject var gameLogic: GameLogic
    @StateObject private var dataManager = DataManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con color de configuración
                Color.settingsBackground
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
                        .foregroundColor(.primary)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                        )
                    }
                    .buttonAnimation()

                    Spacer()

                    // Título
                    Text("Configuración")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Spacer()

                    // Botón Listo (invisible para balancear)
                    Button(action: {
                        gameLogic.backToMenu()
                    }) {
                        Text("Listo")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.8))
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
                .foregroundColor(titleColor)
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
                                .fill(Color.black.opacity(0.8))
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
                .foregroundColor(.playerTitlePurple)
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
                    .foregroundColor(.white)
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

// MARK: - Preview
#Preview {
    SettingsView(gameLogic: GameLogic())
}