import UIKit
import AVKit

class CaptureViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var cameraPreview: PreviewView!
    
    @IBAction func close(_ sender: Any) {
        self.completion?(nil)
    }
    @IBAction func takeSelfie(_ sender: Any) {
        guard let videoConnection = photoOutput.connection(with: AVMediaType.video) else
        {
            NSLog("Failed to get camera connection")
            return
        }
        
        videoConnection.videoOrientation = currentVideoOrientation
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    override func viewDidLoad() {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes:
            [.builtInWideAngleCamera],
                                                         mediaType: .video, position: .front)
        
        guard let captureDevice = discovery.devices.first else {
            NSLog("No capture devices available")
            self.completion?(nil)
            return
        }
        
        do {
            try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        } catch let error {
            NSLog("Failed to add camera to caputre session: \(error)")
            self.completion?(nil)
        }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        captureSession.startRunning()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        self.cameraPreview.setSession(captureSession)
        
        super.viewDidLoad()
    }
    
    typealias CompletionHandler = (UIImage?) -> Void
    var completion : CompletionHandler?
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    
    var currentVideoOrientation: AVCaptureVideoOrientation {
        let orientationMap: [UIDeviceOrientation: AVCaptureVideoOrientation]
        
        orientationMap = [
            .portrait: .portrait,
            .landscapeLeft: .landscapeLeft,
            .landscapeRight: .landscapeRight,
            .portraitUpsideDown: .portraitUpsideDown
        ]
        
        let currentOrientation = UIDevice.current.orientation
        let videoOrientation = orientationMap[currentOrientation, default: .portrait]
        return videoOrientation
    }
    
    override func viewWillLayoutSubviews() {
        self.cameraPreview?.setCameraOrientation(currentVideoOrientation)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            NSLog("Failed to get the photo \(error)")
            return
        }
        
        guard let jpegData = photo.fileDataRepresentation(),
            let image = UIImage(data: jpegData) else {
                NSLog("Failed to get image from encoded data")
                return
        }
        
        self.completion?(image)
    }
}

class PreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setSession(_ session: AVCaptureSession) {
        guard self.previewLayer == nil else {
            NSLog("Warning: \(self.description) attempted to set its preview layer more than once. This is not allowed")
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
        
        self.setNeedsLayout()
    }
    
    func setCameraOrientation(_ orientation: AVCaptureVideoOrientation) {
        previewLayer?.connection?.videoOrientation = orientation
    }
    
    override func layoutSubviews() {
        previewLayer?.frame = self.bounds
    }
}
