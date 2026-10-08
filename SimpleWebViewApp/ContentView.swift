import SwiftUI
import WebKit
import AVFoundation
import MediaPlayer

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        // Chèn JavaScript để ngăn YouTube phát hiện ứng dụng bị chuyển xuống nền (chặn visibilitychange & pagehide)
        let script = """
        document.addEventListener('visibilitychange', function(e) { e.stopImmediatePropagation(); }, true);
        document.addEventListener('pagehide', function(e) { e.stopImmediatePropagation(); }, true);
        Object.defineProperty(document, 'visibilityState', {value: 'visible', writable: true});
        Object.defineProperty(document, 'hidden', {value: false, writable: true});
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

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
        setupAudioSession()
        setupRemoteCommandCenter()
    }

    // 1. Khai báo Audio Session nâng cao
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Lỗi AVAudioSession: \(error)")
        }
    }

    // 2. Kích hoạt Remote Command Center để hệ thống iOS/CarPlay nhận diện trình phát nhạc
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            self.webView?.evaluateJavaScript("document.querySelector('video')?.play()", completionHandler: nil)
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            self.webView?.evaluateJavaScript("document.querySelector('video')?.pause()", completionHandler: nil)
            return .success
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            WebView(url: URL(string: "https://m.youtube.com")!, webView: $webView)
                .edgesIgnoringSafeArea(.top)

            // Dàn nút Footer điều hướng
            HStack {
                Spacer()

                // Nút Trở về (Back)
                Button(action: { webView?.goBack() }) {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Nút Tiến (Forward)
                Button(action: { webView?.goForward() }) {
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
                Button(action: { webView?.reload() }) {
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
