import SwiftUI
// import GoogleMobileAds // Descomentar después de agregar la dependencia
import UIKit

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> UIView {
        // Placeholder temporal hasta que se agregue GoogleMobileAds
        let placeholderView = UIView()
        placeholderView.backgroundColor = UIColor.systemGray5

        let label = UILabel()
        label.text = "AdMob Banner\n\(adUnitID)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.systemGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false

        placeholderView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor)
        ])

        return placeholderView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No necesita actualización
    }
}

// Extension para obtener el root view controller de manera más robusta
extension UIApplication {
    var currentUIWindow: UIWindow? {
        connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
            .map({ $0?.windows.first })
            ?? nil
    }
}

struct AdMobBannerView_Previews: PreviewProvider {
    static var previews: some View {
        AdMobBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716") // Test Ad Unit ID
            .frame(height: 50)
    }
}