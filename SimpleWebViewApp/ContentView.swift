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

        // Chèn script ép video luôn chạy ở chế độ inline & vô hiệu hóa việc tạm dừng khi mất focus tab
        let script = """
        document.addEventListener('visibilitychange', function(e) { e.stopImmediatePropagation(); }, true);
        document.addEventListener('pagehide', function(e) { e.stopImmediatePropagation(); }, true);
        Object.defineProperty(document, 'visibilityState', {value: 'visible', writable: true});
        Object.defineProperty(document, 'hidden', {value: false, writable: true});
        
        setInterval(function() {
            var videos = document.querySelectorAll('video');
            videos.forEach(function(v) {
                v.setAttribute('playsinline', '');
                v.setAttribute('webkit-playsinline', '');
                if (v.paused && !v.ended && v.readyState > 2) {
                    // Giữ trạng thái luôn sẵn sàng phát
                }
            });
        }, 500);
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"
        
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
        setupRemoteCommands()
    }

    // Cấu hình Audio Session để giành quyền ưu tiên phát âm thanh nền trên CarPlay/iOS
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Không thể kích hoạt AudioSession: \(error)")
        }
    }

    // Kết nối các nút bấm trên vô lăng/màn hình ô tô (Play/Pause) với WebView YouTube
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { _ in
            self.webView?.evaluateJavaScript("document.querySelector('video')?.play()", completionHandler: nil)
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { _ in
            self.webView?.evaluateJavaScript("document.querySelector('video')?.pause()", completionHandler: nil)
            return .success
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hiển thị YouTube WebView chiếm toàn màn hình
            WebView(url: URL(string: "https://www.youtube.com")!, webView: $webView)
                .edgesIgnoringSafeArea(.top)

            // Dàn nút Footer điều hướng nhanh
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

                // Nút Trang chủ YouTube (Home)
                Button(action: {
                    let request = URLRequest(url: URL(string: "https://www.youtube.com")!)
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
