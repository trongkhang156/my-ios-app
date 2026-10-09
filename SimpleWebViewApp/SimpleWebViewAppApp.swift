import SwiftUI
import AVFoundation

@main
struct SimpleWebViewAppApp: App {
    init() {
        setupAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Lỗi Audio Session: \(error)")
        }
    }
}
