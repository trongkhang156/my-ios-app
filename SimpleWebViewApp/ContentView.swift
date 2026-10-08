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

        // Script hỗ trợ ép video nhận diện PiP và điều khiển
        let script = """
        document.addEventListener('visibilitychange', function(e) { e.stopImmediatePropagation(); }, true);
        document.addEventListener('pagehide', function(e) { e.stopImmediatePropagation(); }, true);
        
        // Hàm kích hoạt PiP tự động khi app xuống nền
        window.triggerPiP = function() {
            var video = document.querySelector('video');
            if (video && !video.paused) {
                if (video.webkitSetPresentationMode) {
                    video.webkitSetPresentationMode('picture-in-picture');
                }
            }
        };
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
    @Environment(\.scenePhase) private var scenePhase

    init() {
        setupAudioSession()
        setupRemoteCommands()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Lỗi AudioSession: \(error)")
        }
    }

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
            WebView(url: URL(string: "https://www.youtube.com")!, webView: $webView)
                .edgesIgnoringSafeArea(.top)

            // Dàn nút Footer điều hướng nhanh
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
        // Bắt sự kiện khi app chuyển xuống nền (vuốt về Home / mở app khác)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                webView?.evaluateJavaScript("window.triggerPiP();", completionHandler: nil)
            }
        }
    }
}
