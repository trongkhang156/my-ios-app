import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isBubbleActive = false

    var body: some View {
        ZStack {
            if isBubbleActive {
                // Tải WebView (VietMap) chạy ngầm phía dưới bong bóng
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
            isBubbleActive = false // Tắt bong bóng thì quay lại menu
        }
    }
}

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
