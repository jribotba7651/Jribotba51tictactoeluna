import SwiftUI

// MARK: - Extensiones de Color para gradientes personalizados
extension Color {
    // Colores para Luna Mode
    static let lunaModePrimary = Color(red: 1.0, green: 0.7, blue: 0.9) // Rosa claro
    static let lunaModeSecondary = Color(red: 0.9, green: 0.6, blue: 1.0) // Lavanda
    static let lunaModeTertiary = Color(red: 1.0, green: 0.8, blue: 0.6) // Naranja claro

    // Colores para Unbeatable Mode
    static let unbeatablePrimary = Color(red: 1.0, green: 1.0, blue: 0.7) // Amarillo claro
    static let unbeatableSecondary = Color(red: 1.0, green: 0.9, blue: 0.6) // Crema
    static let unbeatableTertiary = Color(red: 0.8, green: 0.9, blue: 1.0) // Azul claro

    // Colores para configuración
    static let settingsBackground = Color(red: 0.95, green: 0.92, blue: 1.0) // Lavanda muy claro
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

    // Gradiente para Unbeatable Mode
    static let unbeatableMode = LinearGradient(
        gradient: Gradient(colors: [
            Color.unbeatablePrimary,
            Color.unbeatableSecondary
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Gradiente para botones de Luna Mode
    static let lunaModeButton = LinearGradient(
        gradient: Gradient(colors: [
            Color.pink.opacity(0.8),
            Color.red.opacity(0.6)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    // Gradiente para botones de Unbeatable Mode
    static let unbeatableModeButton = LinearGradient(
        gradient: Gradient(colors: [
            Color.green.opacity(0.8),
            Color.blue.opacity(0.6)
        ]),
        startPoint: .leading,
        endPoint: .trailing
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
}

// MARK: - Extensión de View para modificadores personalizados
extension View {
    // Modificador para sombras consistentes
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
            .animation(.easeInOut(duration: 0.1), value: UUID())
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
    // Función para obtener emoji aleatorio de celebración
    static func randomCelebrationEmoji() -> String {
        let emojis = ["✨", "🎉", "🎊", "🌟", "💫", "🎆", "🎇"]
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
    static let magicalSparkle = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    static let buttonPress = Animation.easeInOut(duration: 0.1)
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
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID())
            )
    }
}
#endif