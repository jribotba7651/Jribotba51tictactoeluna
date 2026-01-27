import Foundation
import SwiftUI

// MARK: - Gestor de datos persistentes
class DataManager: ObservableObject {
    static let shared = DataManager()

    // MARK: - Claves para UserDefaults
    private enum Keys {
        static let player1Name = "player1Name"
        static let player1Emoji = "player1Emoji"
        static let player2Name = "player2Name"
        static let player2Emoji = "player2Emoji"
        static let player1Wins = "player1Wins"
        static let player2Wins = "player2Wins"
        static let draws = "draws"
        static let soundEnabled = "soundEnabled"
    }

    // MARK: - Configuraciones de jugadores
    @Published var player1Config: PlayerConfig {
        didSet {
            savePlayerConfig(player1Config, for: .player1)
        }
    }

    @Published var player2Config: PlayerConfig {
        didSet {
            savePlayerConfig(player2Config, for: .player2)
        }
    }

    // MARK: - Puntuaciones del juego
    @Published var gameScores: GameScores {
        didSet {
            saveScores()
        }
    }

    // MARK: - Configuraciones adicionales
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }

    private init() {
        // Cargar configuración del jugador 1
        let player1Name = UserDefaults.standard.string(forKey: Keys.player1Name) ?? PlayerConfig.defaultPlayer1.name
        let player1Emoji = UserDefaults.standard.string(forKey: Keys.player1Emoji) ?? PlayerConfig.defaultPlayer1.emoji
        self.player1Config = PlayerConfig(name: player1Name, emoji: player1Emoji)

        // Cargar configuración del jugador 2
        let player2Name = UserDefaults.standard.string(forKey: Keys.player2Name) ?? PlayerConfig.defaultPlayer2.name
        let player2Emoji = UserDefaults.standard.string(forKey: Keys.player2Emoji) ?? PlayerConfig.defaultPlayer2.emoji
        self.player2Config = PlayerConfig(name: player2Name, emoji: player2Emoji)

        // Cargar puntuaciones
        let player1Wins = UserDefaults.standard.integer(forKey: Keys.player1Wins)
        let player2Wins = UserDefaults.standard.integer(forKey: Keys.player2Wins)
        let draws = UserDefaults.standard.integer(forKey: Keys.draws)
        self.gameScores = GameScores(player1Wins: player1Wins, player2Wins: player2Wins, draws: draws)

        // Cargar configuración adicional
        self.soundEnabled = UserDefaults.standard.bool(forKey: Keys.soundEnabled)
    }

    // MARK: - Métodos de guardado
    private func savePlayerConfig(_ config: PlayerConfig, for player: Player) {
        switch player {
        case .player1:
            UserDefaults.standard.set(config.name, forKey: Keys.player1Name)
            UserDefaults.standard.set(config.emoji, forKey: Keys.player1Emoji)
        case .player2:
            UserDefaults.standard.set(config.name, forKey: Keys.player2Name)
            UserDefaults.standard.set(config.emoji, forKey: Keys.player2Emoji)
        case .none:
            break
        }
    }

    private func saveScores() {
        UserDefaults.standard.set(gameScores.player1Wins, forKey: Keys.player1Wins)
        UserDefaults.standard.set(gameScores.player2Wins, forKey: Keys.player2Wins)
        UserDefaults.standard.set(gameScores.draws, forKey: Keys.draws)
    }

    // MARK: - Métodos públicos
    func resetAllScores() {
        gameScores.reset()
    }

    func addWin(for player: Player) {
        gameScores.addWin(for: player)
    }

    func getPlayerConfig(for player: Player) -> PlayerConfig {
        switch player {
        case .player1:
            return player1Config
        case .player2:
            return player2Config
        case .none:
            return PlayerConfig(name: "", emoji: "")
        }
    }

    func updatePlayerName(_ name: String, for player: Player) {
        switch player {
        case .player1:
            player1Config.name = name
        case .player2:
            player2Config.name = name
        case .none:
            break
        }
    }

    func updatePlayerEmoji(_ emoji: String, for player: Player) {
        switch player {
        case .player1:
            player1Config.emoji = emoji
        case .player2:
            player2Config.emoji = emoji
        case .none:
            break
        }
    }

    func getPlayerEmoji(for player: Player) -> String {
        switch player {
        case .player1:
            return player1Config.emoji
        case .player2:
            return player2Config.emoji
        case .none:
            return ""
        }
    }

    func getPlayerName(for player: Player) -> String {
        switch player {
        case .player1:
            return player1Config.name
        case .player2:
            return player2Config.name
        case .none:
            return ""
        }
    }
}