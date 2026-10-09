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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Lỗi Audio Session: \(error)")
        }
    }
}
