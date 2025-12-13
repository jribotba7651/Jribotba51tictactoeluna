import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    let isActive: Bool

    func makeUIView(context: Context) -> ConfettiUIView {
        return ConfettiUIView()
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {
        if isActive {
            uiView.startConfetti()
        } else {
            uiView.stopConfetti()
        }
    }
}

class ConfettiUIView: UIView {
    private var emitterLayer: CAEmitterLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEmitter()
    }

    private func setupEmitter() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -50)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)

        // Células de confetti
        let colors: [UIColor] = [
            .systemPink, .systemPurple, .systemOrange,
            .systemBlue, .systemGreen, .systemYellow, .systemRed
        ]

        var cells: [CAEmitterCell] = []

        // Círculos de colores
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 3
            cell.lifetime = 4.0
            cell.velocity = 200
            cell.velocityRange = 100
            cell.emissionLongitude = CGFloat.pi
            cell.emissionRange = CGFloat.pi / 4
            cell.spin = 3.5
            cell.spinRange = 1.0
            cell.scaleRange = 0.5
            cell.scale = 0.8

            // Crear imagen de círculo
            let size = CGSize(width: 12, height: 12)
            let renderer = UIGraphicsImageRenderer(size: size)
            let circleImage = renderer.image { context in
                color.setFill()
                context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
            cell.contents = circleImage.cgImage

            cells.append(cell)
        }

        // Estrellas
        let starCell = CAEmitterCell()
        starCell.birthRate = 2
        starCell.lifetime = 5.0
        starCell.velocity = 150
        starCell.velocityRange = 50
        starCell.emissionLongitude = CGFloat.pi
        starCell.emissionRange = CGFloat.pi / 3
        starCell.spin = 2.0
        starCell.spinRange = 1.0
        starCell.scaleRange = 0.3
        starCell.scale = 1.0

        // Crear imagen de estrella
        let starSize = CGSize(width: 20, height: 20)
        let starRenderer = UIGraphicsImageRenderer(size: starSize)
        let starImage = starRenderer.image { context in
            let star = "✨"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.systemYellow
            ]
            star.draw(in: CGRect(origin: .zero, size: starSize), withAttributes: attributes)
        }
        starCell.contents = starImage.cgImage
        cells.append(starCell)

        // Corazones
        let heartCell = CAEmitterCell()
        heartCell.birthRate = 1.5
        heartCell.lifetime = 6.0
        heartCell.velocity = 120
        heartCell.velocityRange = 30
        heartCell.emissionLongitude = CGFloat.pi
        heartCell.emissionRange = CGFloat.pi / 6
        heartCell.spin = 1.0
        heartCell.spinRange = 0.5
        heartCell.scaleRange = 0.4
        heartCell.scale = 0.9

        // Crear imagen de corazón
        let heartSize = CGSize(width: 18, height: 18)
        let heartRenderer = UIGraphicsImageRenderer(size: heartSize)
        let heartImage = heartRenderer.image { context in
            let heart = "💖"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.systemPink
            ]
            heart.draw(in: CGRect(origin: .zero, size: heartSize), withAttributes: attributes)
        }
        heartCell.contents = heartImage.cgImage
        cells.append(heartCell)

        emitter.emitterCells = cells
        emitter.birthRate = 0

        layer.addSublayer(emitter)
        self.emitterLayer = emitter
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer?.emitterPosition = CGPoint(x: bounds.midX, y: -50)
        emitterLayer?.emitterSize = CGSize(width: bounds.width, height: 1)
    }

    func startConfetti() {
        emitterLayer?.birthRate = 1.0

        // Detener automáticamente después de 3 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.stopConfetti()
        }
    }

    func stopConfetti() {
        emitterLayer?.birthRate = 0
    }
}

// Extension para el modifier
extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        self.overlay(
            ConfettiView(isActive: isActive.wrappedValue)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        )
    }
}