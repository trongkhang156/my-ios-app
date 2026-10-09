import SwiftUI
import WebKit
import AVKit
import AVFoundation

struct ContentView: View {
    @State private var urlString: String = "https://maps.google.com"

    var body: some View {
        VStack(spacing: 0) {
            // Thanh chọn dịch vụ bản đồ
            HStack(spacing: 12) {
                Button(action: { urlString = "https://maps.google.com" }) {
                    Text("Google Maps")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: { urlString = "https://www.waze.com/live-map/" }) {
                    Text("Waze Web")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.cyan)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()

            // Màn hình WebView tích hợp luồng PiP nổi
            PiPMapView(urlString: $urlString)
        }
    }
}

struct PiPMapView: UIViewRepresentable {
    @Binding var urlString: String

    func makeUIView(context: Context) -> PiPContainerView {
        let view = PiPContainerView()
        view.loadURL(urlString)
        return view
    }

    func updateUIView(_ uiView: PiPContainerView, context: Context) {
        uiView.loadURL(urlString)
    }
}

class PiPContainerView: UIView, AVPictureInPictureControllerDelegate, AVPictureInPictureSampleBufferPlaybackDelegate {
    private var webView: WKWebView!
    private var sampleBufferLayer = AVSampleBufferDisplayLayer()
    private var pipController: AVPictureInPictureController?
    private var renderTimer: Timer?
    private var currentURL: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
        setupPiP()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
        setupPiP()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(webView)
    }

    func loadURL(_ urlString: String) {
        guard currentURL != urlString, let url = URL(string: urlString) else { return }
        currentURL = urlString
        webView.load(URLRequest(url: url))
    }

    private func setupPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

        sampleBufferLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        sampleBufferLayer.videoGravity = .resizeAspect
        layer.addSublayer(sampleBufferLayer)

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: sampleBufferLayer,
            playbackDelegate: self
        )
        
        pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController?.delegate = self
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true

        startRendering()
    }

    private func startRendering() {
        renderTimer?.invalidate()
        // Render lại giao diện bản đồ 5 lần/giây để đưa vào khung PiP nổi
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.captureAndEnqueueFrame()
        }
    }

    private func captureAndEnqueueFrame() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        let renderer = UIGraphicsImageRenderer(bounds: webView.bounds)
        let image = renderer.image { _ in
            webView.drawHierarchy(in: webView.bounds, afterScreenUpdates: false)
        }

        guard let pixelBuffer = image.toCVPixelBuffer() else { return }

        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard let format = formatDescription else { return }

        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 5),
            presentationTimeStamp: CMTime(value: Int64(CACurrentMediaTime() * 1000), timescale: 1000),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: format,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        if let buffer = sampleBuffer, sampleBufferLayer.isReadyForMoreMediaData {
            sampleBufferLayer.enqueue(buffer)
        }
    }

    // Delegate xử lý PiP Playback
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: .positiveInfinite)
    }
    
    func pictureInPictureControllerIsPlaybackActive(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return true
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newSize: CMVideoDimensions) {}
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        guard width > 0, height > 0 else { return nil }

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapImageCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        return buffer
    }
}
