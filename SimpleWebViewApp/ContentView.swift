import SwiftUI
import UIKit

struct ContentView: View {
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Chọn ứng dụng điều hướng")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            MapAppButton(title: "Mở Google Maps", color: .blue, iconName: "map.fill") {
                openApp(urlScheme: "comgooglemaps://", fallbackAppStore: "https://apps.apple.com/app/id585027354")
            }
            
            MapAppButton(title: "Mở Apple Maps (Mặc định)", color: .green, iconName: "location.fill") {
                openApp(urlScheme: "maps://", fallbackAppStore: "")
            }
            
            MapAppButton(title: "Mở VietMap Live", color: .orange, iconName: "car.fill") {
                openApp(urlScheme: "vietmap://", fallbackAppStore: "https://apps.apple.com/app/id1593339380")
            }
            
            MapAppButton(title: "Mở Waze", color: .cyan, iconName: "arrow.triangle.turn.up.right.diamond.fill") {
                openApp(urlScheme: "waze://", fallbackAppStore: "https://apps.apple.com/app/id323229106")
            }

            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thông báo"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func openApp(urlScheme: String, fallbackAppStore: String) {
        guard let appURL = URL(string: urlScheme) else { return }
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else {
            if !fallbackAppStore.isEmpty, let storeURL = URL(string: fallbackAppStore) {
                UIApplication.shared.open(storeURL, options: [:], completionHandler: nil)
            } else {
                alertMessage = "Ứng dụng chưa được cài đặt trên thiết bị này."
                showAlert = true
            }
        }
    }
}

struct MapAppButton: View {
    var title: String
    var color: Color
    var iconName: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
}
