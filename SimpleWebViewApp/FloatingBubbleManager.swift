import UIKit

class FloatingBubbleManager {
    static let shared = FloatingBubbleManager()
    private var floatingWindow: UIWindow?
    private var onCloseCallback: (() -> Void)?

    func showBubble(onClose: @escaping () -> Void) {
        guard floatingWindow == nil else { return }
        onCloseCallback = onClose

        let window = UIWindow(frame: CGRect(x: 30, y: 150, width: 70, height: 70))
        window.windowLevel = UIWindow.Level.alert + 100
        window.backgroundColor = .clear
        window.clipsToBounds = false

        let vc = UIViewController()
        let bubbleView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        bubbleView.backgroundColor = UIColor.systemOrange
        bubbleView.layer.cornerRadius = 30
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.4
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 4)
        
        let label = UILabel(frame: bubbleView.bounds)
        label.text = "MAP"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 14)
        bubbleView.addSubview(label)

        let closeButton = UIButton(frame: CGRect(x: 40, y: -5, width: 25, height: 25))
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = .systemRed
        closeButton.layer.cornerRadius = 12.5
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        vc.view.addSubview(bubbleView)
        vc.view.addSubview(closeButton)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        window.addGestureRecognizer(panGesture)

        window.rootViewController = vc
        window.isHidden = false
        floatingWindow = window
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let window = floatingWindow else { return }
        let translation = gesture.translation(in: window)
        window.center = CGPoint(x: window.center.x + translation.x, y: window.center.y + translation.y)
        gesture.setTranslation(.zero, in: window)
    }

    @objc private func closeButtonTapped() {
        floatingWindow?.isHidden = true
        floatingWindow = nil
        onCloseCallback?()
    }
}
