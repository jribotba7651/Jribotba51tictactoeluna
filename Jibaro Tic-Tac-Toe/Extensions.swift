import SwiftUI

// MARK: - Extensiones de Color para gradientes personalizados
extension Color {
    // Inicializador de Color con valor hexadecimal
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    // Colores para Luna Mode - Gradiente más vibrante
    static let lunaModePrimary = Color(hex: "FF6B9D")   // #FF6B9D
    static let lunaModeSecondary = Color(hex: "C471ED") // #C471ED
    static let lunaModeTertiary = Color(hex: "FFB88C")  // #FFB88C

    // Colores para Unbeatable Mode - Gradiente más vibrante
    static let unbeatablePrimary = Color(hex: "FFF4B3")   // #FFF4B3
    static let unbeatableSecondary = Color(hex: "FFE066") // #FFE066

    // Colores para configuración
    static let settingsBackground = Color(red: 0.95, green: 0.92, blue: 1.0) // Lavanda muy claro

    // Colores para score cards
    static let scorePlayer1 = Color(hex: "4ECCA3") // Verde menta para primer jugador
    static let scoreDraw = Color(hex: "FFB84D")    // Naranja para empates
    static let scorePlayer2 = Color(hex: "5B9FED") // Azul para segundo jugador

    // Colores para menú principal - Gradiente más vibrante
    static let menuPrimary = Color(hex: "FFB6C1")   // #FFB6C1
    static let menuSecondary = Color(hex: "DDA0DD") // #DDA0DD
    static let menuTertiary = Color(hex: "FFB88C")  // #FFB88C

    // Colores fuertes para títulos de configuración
    static let playerTitlePink = Color(hex: "FF1493")   // Deep Pink
    static let playerTitleBlue = Color(hex: "1E90FF")   // Dodger Blue
    static let playerTitlePurple = Color(hex: "8A2BE2") // Blue Violet
}

// MARK: - Extensión de LinearGradient para gradientes personalizados
extension LinearGradient {
    // Gradiente para Luna Mode
    static let lunaMode = LinearGradient(
        gradient: Gradient(colors: [
            Color.lunaModePrimary,
            Color.lunaModeSecondary,
            Color.lunaModeTertiary
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Gradiente para Unbeatable Mode - Ahora usa la estética de Luna Mode
    static let unbeatableMode = LinearGradient(
        gradient: Gradient(colors: [
            Color.lunaModePrimary,
            Color.lunaModeSecondary,
            Color.lunaModeTertiary
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Gradiente para botones de Luna Mode
    static let lunaModeButton = LinearGradient(
        gradient: Gradient(colors: [
            Color.pink,
            Color.red
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    // Gradiente para botones de Unbeatable Mode - Ahora usa la estética de Luna Mode
    static let unbeatableModeButton = LinearGradient(
        gradient: Gradient(colors: [
            Color.pink,
            Color.red
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    // Gradiente para el fondo del menú principal
    static let mainMenu = LinearGradient(
        gradient: Gradient(colors: [
            Color.menuPrimary,
            Color.menuSecondary,
            Color.menuTertiary
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Gradiente para tarjetas del menú
    static let menuCardLuna = LinearGradient(
        gradient: Gradient(colors: [
            Color.pink.opacity(0.7),
            Color.orange.opacity(0.5)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let menuCardUnbeatable = LinearGradient(
        gradient: Gradient(colors: [
            Color.blue.opacity(0.7),
            Color.purple.opacity(0.5)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let menuCardInfinity = LinearGradient(
        gradient: Gradient(colors: [
            Color.purple.opacity(0.7),
            Color.indigo.opacity(0.5)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let menuCardMemory = LinearGradient(
        gradient: Gradient(colors: [
            Color.green.opacity(0.7),
            Color.teal.opacity(0.5)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Extensión de View para modificadores personalizados
extension View {
    // Modificador para sombras consistentes
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    // Modificador para sombras dobles (profundidad mejorada)
    func doubleShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
    }

    // Modificador para sombras de texto
    func textShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
    }

    // Modificador para bordes redondeados consistentes
    func roundedBorder(cornerRadius: CGFloat = 15, lineWidth: CGFloat = 2, color: Color = Color.gray.opacity(0.3)) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }

    // Modificador para animaciones de botones
    func buttonAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.3), value: UUID())
            .drawingGroup()
    }

    // Modificador para efectos mágicos de Luna Mode
    func magicalEffect() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink.opacity(0.5),
                                Color.purple.opacity(0.3),
                                Color.orange.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 1)
            )
            .shadow(color: Color.pink.opacity(0.3), radius: 8, x: 0, y: 0)
    }
}

// MARK: - Extensión de String para emojis animados
extension String {
    // Función para obtener emoji aleatorio de celebración con más variedad
    static func randomCelebrationEmoji() -> String {
        let emojis = ["✨", "🎉", "🎊", "🌟", "💫", "🎆", "🎇", "🔥", "⚡", "🌈", "🦄", "🎈", "🎁", "🏆", "💎", "🌺", "🎯", "🚀", "🌙", "⭐"]
        return emojis.randomElement() ?? "✨"
    }

    // Función para obtener emoji de corazón aleatorio
    static func randomHeartEmoji() -> String {
        let hearts = ["❤️", "💕", "💖", "💝", "💘", "💓", "💗"]
        return hearts.randomElement() ?? "❤️"
    }
}

// MARK: - Extensión de Animation para animaciones personalizadas
extension Animation {
    static let magicalSparkle = Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)
    static let buttonPress = Animation.easeInOut(duration: 0.3)
    static let gameTransition = Animation.easeInOut(duration: 0.3)
}

// MARK: - Extensión para efectos de vibración (haptic feedback)
#if canImport(UIKit)
import UIKit

extension View {
    func onTapHaptic() -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }

    func onGameWinHaptic() -> some View {
        self.onAppear {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()

            // Vibración adicional para celebración
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                impactFeedback.impactOccurred()
            }
        }
    }

    func cellTapHaptic() -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Modificadores de animación avanzados
extension View {
    func pulseAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: UUID())
    }

    func bounceOnTap() -> some View {
        self
            .scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                    // La animación se maneja en el estado de la vista
                }
            }
    }

    func sparkleEffect() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink.opacity(0.8),
                                Color.purple.opacity(0.6),
                                Color.orange.opacity(0.7),
                                Color.pink.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: UUID())
            )
    }
}
#endif

// MARK: - Estilos de Botones Uniformes
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    let size: ButtonSize

    enum ButtonSize {
        case small, medium, large

        var padding: (horizontal: CGFloat, vertical: CGFloat) {
            switch self {
            case .small: return (16, 8)
            case .medium: return (20, 12)
            case .large: return (24, 16)
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, size.padding.horizontal)
            .padding(.vertical, size.padding.vertical)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.8), color.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.4), radius: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .gray.opacity(0.2), radius: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct GameCardStyle: ButtonStyle {
    let gradient: LinearGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(gradient)
                    .overlay(
                        // Efecto de vidrio
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Sistema de Tipografía Uniforme
struct GameTypography {
    // Títulos principales
    static func gameTitle(size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Subtítulos
    static func gameSubtitle(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    // Texto de botones
    static func buttonText(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    // Texto de estadísticas
    static func statText(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // Texto descriptivo
    static func bodyText(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: - Paleta de Colores Uniforme
struct GameColors {
    // Colores primarios
    static let primary = Color.blue
    static let secondary = Color.green
    static let accent = Color.orange
    static let danger = Color.red
    static let warning = Color.yellow

    // Gradientes principales
    static let primaryGradient = LinearGradient(
        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let secondaryGradient = LinearGradient(
        colors: [Color.green.opacity(0.8), Color.teal.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Colores de fondo
    static let backgroundPrimary = LinearGradient(
        colors: [
            Color.blue.opacity(0.1),
            Color.purple.opacity(0.05),
            Color.pink.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color.white.opacity(0.8)
    static let overlayBackground = Color.black.opacity(0.7)
}

// MARK: - Modificadores de Vista Uniformes
extension View {
    // Aplicar estilo de carta estándar
    func standardCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(GameColors.cardBackground)
                    .shadow(color: .gray.opacity(0.2), radius: 5)
            )
    }

    // Aplicar fondo estándar del juego
    func gameBackground() -> some View {
        self
            .background(GameColors.backgroundPrimary.ignoresSafeArea())
    }

    // Aplicar estilo de título estándar
    func gameTitle(_ text: String, color: Color = .primary) -> some View {
        VStack {
            self
            Text(text)
                .font(GameTypography.gameTitle())
                .foregroundColor(color)
                .multilineTextAlignment(.center)
        }
    }
}