import SwiftUI
import WebKit
import UIKit

struct ContentView: View {
    @State private var isBubbleActive = false

    var body: some View {
        ZStack {
            if isBubbleActive {
                WebViewWrapper(url: URL(string: "https://maps.google.com")!)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack(spacing: 20) {
                    Text("Chọn dịch vụ điều hướng")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        launchBubble()
                    }) {
                        Text("Khởi chạy VietMap (Bong bóng nổi)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }
    
    private func launchBubble() {
        isBubbleActive = true
        FloatingBubbleManager.shared.showBubble {
            isBubbleActive = false
        }
    }
}

// Wrapper bọc WKWebView cho SwiftUI
struct WebViewWrapper: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// Trình quản lý Bong bóng nổi gộp chung vào đây để Xcode nhận diện được
class FloatingBubbleManager {
    static let shared = FloatingBubbleManager()
    private var floatingWindow: UIWindow?
    private var onCloseCallback: (() -> Void)?

    func showBubble(onClose: @escaping () -> Void) {
        guard floatingWindow == nil else { return }
        onCloseCallback = onClose

        // Lấy active scene của SwiftUI để gắn UIWindow (Bắt buộc cho iOS mới)
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(x: 30, y: 150, width: 70, height: 70)
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
