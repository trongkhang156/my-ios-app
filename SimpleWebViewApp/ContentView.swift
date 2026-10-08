import SwiftUI
import WebKit
import AVFoundation

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Cấu hình bắt buộc cho PiP & Inline Playback
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Chèn script ép video hiển thị controls native hỗ trợ PiP
        let script = """
        setInterval(function() {
            var videos = document.querySelectorAll('video');
            videos.forEach(function(v) {
                v.setAttribute('playsinline', '');
                v.setAttribute('webkit-playsinline', '');
            });
        }, 1000);
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.allowsBackForwardNavigationGestures = true
        
        // Dùng User Agent Desktop/iPad để YouTube hiển thị đầy đủ nút PiP trên trình phát
        wv.customUserAgent = "Mozilla/5.0 (iPad; CPU OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"
        
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
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("AudioSession Error: \(error)")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            WebView(url: URL(string: "https://www.youtube.com")!, webView: $webView)
                .edgesIgnoringSafeArea(.top)

            // Thanh công cụ Footer
            HStack {
                Spacer()

                Button(action: { webView?.goBack() }) {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: { webView?.goForward() }) {
                    Image(systemName: "chevron.forward")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: {
                    let request = URLRequest(url: URL(string: "https://www.youtube.com")!)
                    webView?.load(request)
                }) {
                    Image(systemName: "house")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

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
