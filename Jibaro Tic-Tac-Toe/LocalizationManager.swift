import SwiftUI
import Foundation

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: Language = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.code, forKey: "AppLanguage")
            objectWillChange.send()
        }
    }

    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language.allCases.first(where: { $0.code == savedLanguage }) {
            self.currentLanguage = language
        } else {
            // Default to English if no preference is saved
            self.currentLanguage = .english
        }
    }

    func localizedString(for key: String) -> String {
        // For now, we'll use a simple dictionary approach
        let strings = getLocalizedStrings()
        return strings[key] ?? key
    }

    private func getLocalizedStrings() -> [String: String] {
        let isSpanish = currentLanguage == .spanish
        return [
            "luna_mode": isSpanish ? "🌙 Modo Luna" : "🌙 Luna Mode",
            "unbeatable_mode": isSpanish ? "🤖 Modo Invencible" : "🤖 Unbeatable Mode",
            "infinity_level": isSpanish ? "∞ Nivel Infinito" : "∞ Infinity Level",
            "menu": isSpanish ? "Menú" : "Menu",
            "new_game": isSpanish ? "Nueva Partida" : "New Game",
            "settings": isSpanish ? "Configuración" : "Settings",
            "done": isSpanish ? "Listo" : "Done",
            "player_1": isSpanish ? "Jugador 1" : "Player 1",
            "player_2": isSpanish ? "Jugador 2" : "Player 2",
            "name": isSpanish ? "Nombre:" : "Name:",
            "emoji": "Emoji:",
            "player_name_placeholder": isSpanish ? "Nombre del jugador" : "Player name",
            "game_configuration": isSpanish ? "Configuración del Juego" : "Game Configuration",
            "game_sounds": isSpanish ? "Sonidos del juego:" : "Game sounds:",
            "reset_scores": isSpanish ? "Reiniciar Puntuaciones" : "Reset Scores",
            "purchases": isSpanish ? "💰 Compras" : "💰 Purchases",
            "ads_removed": isSpanish ? "Anuncios Removidos" : "Ads Removed",
            "language": isSpanish ? "Idioma:" : "Language:",
            "luna_won": isSpanish ? "¡Luna ganó! ✨🎉" : "¡Luna won! ✨🎉",
            "back_button": isSpanish ? "Volver" : "Back",
            "infinite_tic_tac_toe": isSpanish ? "Tic-Tac-Toe Infinito" : "Infinite Tic-Tac-Toe",
            // New strings from SettingsView
            "thanks_purchase": isSpanish ? "¡Gracias por tu compra! Disfruta del juego sin anuncios." : "Thank you for your purchase! Enjoy the game without ads.",
            "restore_purchases": isSpanish ? "Restaurar Compras" : "Restore Purchases",
            "remove_ads": isSpanish ? "🚫 Remover Anuncios" : "🚫 Remove Ads",
            "no_interruptions": isSpanish ? "Disfruta del juego sin interrupciones" : "Enjoy the game without interruptions",
            "buy": isSpanish ? "Comprar" : "Buy",
            "restore": isSpanish ? "Restaurar" : "Restore",
            "processing": isSpanish ? "Procesando..." : "Processing...",
            "purchase_success": isSpanish ? "¡Compra Exitosa!" : "Purchase Successful!",
            "ads_removed_message": isSpanish ? "Los anuncios han sido removidos. ¡Gracias por tu compra!" : "Ads have been removed. Thank you for your purchase!",
            "purchase_error": isSpanish ? "Error en la Compra" : "Purchase Error",
            "purchase_error_message": isSpanish ? "Hubo un problema con la compra. Inténtalo de nuevo." : "There was a problem with the purchase. Please try again.",
            "ok": isSpanish ? "OK" : "OK"
        ]
    }
}

// MARK: - Language Enum
enum Language: String, CaseIterable {
    case system = "system"
    case english = "en"
    case spanish = "es"

    var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("System", comment: "")
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }

    var code: String {
        return self.rawValue
    }

    var flag: String {
        switch self {
        case .system:
            return "🌐"
        case .english:
            return "🇺🇸"
        case .spanish:
            return "🇪🇸"
        }
    }
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
}

// MARK: - SwiftUI Environment Extension
struct LocalizationEnvironment: EnvironmentKey {
    static let defaultValue: LocalizationManager = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationEnvironment.self] }
        set { self[LocalizationEnvironment.self] = newValue }
    }
}