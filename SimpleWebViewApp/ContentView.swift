import SwiftUI
import WebKit
import AVFoundation

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        
        let request = URLRequest(url: url)
        wv.load(request)

        DispatchQueue.main.async {
            self.webView = wv
        }

        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView: View {
    @State private var webView: WKWebView? = nil

    init() {
        // Kích hoạt Audio Session ngầm cho phép âm thanh chạy liên tục khi thoát ra Home / khoá màn hình / kết nối CarPlay
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Lỗi khởi tạo AVAudioSession: \(error)")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hiển thị YouTube WebView
            WebView(url: URL(string: "https://m.youtube.com")!, webView: $webView)
                .edgesIgnoringSafeArea(.top)

            // Dàn nút điều hướng ở Footer (Trở về, Tiến, Trang chủ, Tải lại)
            HStack {
                Spacer()

                // Nút Trở về (Back)
                Button(action: {
                    webView?.goBack()
                }) {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Nút Tiến (Forward)
                Button(action: {
                    webView?.goForward()
                }) {
                    Image(systemName: "chevron.forward")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Nút Trang chủ (Home)
                Button(action: {
                    let request = URLRequest(url: URL(string: "https://m.youtube.com")!)
                    webView?.load(request)
                }) {
                    Image(systemName: "house")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Nút Tải lại (Reload)
                Button(action: {
                    webView?.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -2)
        }
    }
}
