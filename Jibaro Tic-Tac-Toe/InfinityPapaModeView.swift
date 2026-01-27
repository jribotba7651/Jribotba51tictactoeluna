import SwiftUI

struct InfinityPapaModeView: View {
    let mainGameLogic: GameLogic
    @StateObject private var gameLogic = InfinityGameLogic()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.indigo.opacity(0.3),
                    Color.purple.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if gameLogic.showingModeSelector {
                modeSelectorView
            } else {
                selectedGameView
            }
        }
    }
    
    // MARK: - Mode Selector
    
    private var modeSelectorView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Mini-juegos disponibles
            ScrollView {
                VStack(spacing: 25) {
                    Spacer(minLength: 20)
                    
                    ForEach(InfinitySubMode.allCases, id: \.self) { mode in
                        MiniGameCard(mode: mode) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                gameLogic.selectSubMode(mode)
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                // Botón volver
                Button(action: {
                    mainGameLogic.backToMenu()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                        )
                }
                .buttonAnimation()
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Título
            HStack(spacing: 8) {
                Text("∞")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Infinity Papá Mode")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("3 mini-juegos para toda la familia")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 20)
        .padding(.bottom, 15)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Selected Game View
    
    @ViewBuilder
    private var selectedGameView: some View {
        if let mode = gameLogic.currentSubMode {
            switch mode {
            case .infiniteTicTacToe:
                InfiniteTicTacToeView(gameLogic: gameLogic, onBack: {
                    withAnimation {
                        gameLogic.backToModeSelector()
                    }
                })
                
            case .threeInOne:
                ThreeInOneView(gameLogic: gameLogic, onBack: {
                    withAnimation {
                        gameLogic.backToModeSelector()
                    }
                })
            }
        }
    }
}

// MARK: - Mini Game Card

struct MiniGameCard: View {
    let mode: InfinitySubMode
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                // Header con icono y emoji
                HStack(spacing: 12) {
                    // Emoji grande
                    Text(mode.emoji)
                        .font(.system(size: 44))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(mode.subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Icono SF Symbol
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Descripción según el modo
                descriptionView
                
                // Botón de acción
                HStack {
                    Spacer()
                    
                    Text("Jugar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: mode.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: mode.gradientColors[0].opacity(0.3), radius: 15, x: 0, y: 10)
            )
        }
        .buttonAnimation()
    }
    
    @ViewBuilder
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch mode {
            case .infiniteTicTacToe:
                FeatureRow(icon: "arrow.up.left.and.arrow.down.right", text: "Tablero que crece automáticamente")
                FeatureRow(icon: "brain", text: "IA que se adapta a tu nivel")
                FeatureRow(icon: "line.diagonal", text: "5 en línea para ganar")
                
            case .threeInOne:
                FeatureRow(icon: "person.2.fill", text: "2-4 jugadores en el mismo dispositivo")
                FeatureRow(icon: "timer", text: "Modo clásico, cronometrado y patrón")
                FeatureRow(icon: "bolt.fill", text: "Partidas rápidas y divertidas")
            }
        }
        .padding(.top, 5)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}


// MARK: - Preview

#Preview {
    InfinityPapaModeView(mainGameLogic: GameLogic())
}
