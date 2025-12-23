import SwiftUI
import AppKit
import AVFoundation

struct CameraPreviewView: NSViewRepresentable {
    let captureSession: AVCaptureSession
    
    func makeNSView(context: Context) -> CameraPreviewNSView {
        let view = CameraPreviewNSView()
        view.setupPreviewLayer(with: captureSession)
        return view
    }
    
    func updateNSView(_ nsView: CameraPreviewNSView, context: Context) {
        nsView.updateFrame()
    }
}

class CameraPreviewNSView: NSView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    func setupPreviewLayer(with session: AVCaptureSession) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer = layer
        self.previewLayer = layer
        updateFrame()
    }
    
    func updateFrame() {
        previewLayer?.frame = bounds
    }
    
    override func layout() {
        super.layout()
        updateFrame()
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        updateFrame()
    }
}

