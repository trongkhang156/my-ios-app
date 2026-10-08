import SwiftUI
import WebKit

struct ContentView: View {
@State private var urlString: String = "https://google.com"
@State private var activeURL: URL? = URL(string: "https://google.com")
@State private var isLoading: Bool = false
@State private var canGoBack: Bool = false
@State private var canGoForward: Bool = false
@State private var webView = WKWebView()

var body: some View {
    VStack(spacing: 0) {
        HStack(spacing: 8) {
            TextField("URL...", text: $urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .onSubmit {
                    loadCurrentInput()
                }

            Button(action: {
                loadCurrentInput()
            }) {
                Text("Go")
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(10)
        .background(Color(UIColor.systemGroupedBackground))

        if isLoading {
            ProgressView()
                .progressViewStyle(LinearProgressViewStyle())
        }

        WebViewContainer(
            webView: webView,
            url: activeURL,
            isLoading: $isLoading,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward
        )

        HStack {
            Button(action: { webView.goBack() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            .disabled(!canGoBack)

            Spacer()

            Button(action: { webView.goForward() }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .disabled(!canGoForward)

            Spacer()

            Button(action: { webView.reload() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
            }

            Spacer()

            Button(action: {
                urlString = "https://google.com"
                loadCurrentInput()
            }) {
                Image(systemName: "house")
                    .font(.title2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

private func loadCurrentInput() {
    var formatted = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    if formatted.isEmpty { return }

    if !formatted.lowercased().hasPrefix("http://") && !formatted.lowercased().hasPrefix("https://") {
        formatted = "https://" + formatted
    }

    if let url = URL(string: formatted) {
        urlString = formatted
        activeURL = url
    }
}


}

struct WebViewContainer: UIViewRepresentable {
let webView: WKWebView
let url: URL?
@Binding var isLoading: Bool
@Binding var canGoBack: Bool
@Binding var canGoForward: Bool

func makeCoordinator() -> Coordinator {
    Coordinator(self)
}

func makeUIView(context: Context) -> WKWebView {
    webView.navigationDelegate = context.coordinator
    if let url = url {
        webView.load(URLRequest(url: url))
    }
    return webView
}

func updateUIView(_ uiView: WKWebView, context: Context) {
    if let url = url, uiView.url != url {
        uiView.load(URLRequest(url: url))
    }
}

class Coordinator: NSObject, WKNavigationDelegate {
    var parent: WebViewContainer

    init(_ parent: WebViewContainer) {
        self.parent = parent
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        parent.isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parent.isLoading = false
        parent.canGoBack = webView.canGoBack
        parent.canGoForward = webView.canGoForward
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        parent.isLoading = false
    }
}


}