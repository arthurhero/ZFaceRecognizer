import UIKit
import AVFoundation

var raw = CIImage()
var res : UIImage? = nil
var rect : CGRect? = nil

var stalk : Bool = false

class detectorViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
    
    var faceViews : [UIView] = []
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBAction func stalkButtonTapped(_ sender: Any) {
        res = UIImage(ciImage: raw)
        stalk = true
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSession.Preset.photo
            captureSession?.beginConfiguration()
            if (captureSession?.canAddInput(input))! {
                captureSession?.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCMPixelFormat_32BGRA)]
            output.alwaysDiscardsLateVideoFrames = true
            
            if (captureSession?.canAddOutput(output))! {
                captureSession?.addOutput(output)
            }
            
            captureSession?.commitConfiguration()
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = cameraView.layer.bounds
            cameraView.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
        } catch let error as NSError {
            print(error)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer : CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        
        raw = ciImage
        let imageSize : CGSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        
        let allFeatures = faceDetector?.features(in: ciImage, options: nil)
        
        guard let features = allFeatures as! [CIFaceFeature]? else { return }
        
        if (features.isEmpty) {
            if (!faceViews.isEmpty) {
                for i in 0 ... faceViews.count - 1 {
                    DispatchQueue.main.sync {
                        self.cameraView.viewWithTag(i+1)?.removeFromSuperview()
                    }
                }
                faceViews.removeAll()
            }
            return
        }
        
        let fcount = features.endIndex - features.startIndex
        
        if faceViews.count > fcount {
            for i in fcount ... faceViews.count - 1 {
                DispatchQueue.main.sync {
                    self.cameraView.viewWithTag(i+1)?.removeFromSuperview()
                }
            }
            faceViews = Array(faceViews[0...fcount-1])
        }
        
        for i in 0 ... fcount-1 {
            let feature = features[i]
                if i == 0 {
                    rect = feature.bounds
                }
                
            let faceRect = calculateFaceRect(faceBounds: feature.bounds, imgeSize: imageSize)
            DispatchQueue.main.sync {
                UIView.animate(withDuration: 0.2) {
                    var faceFrameView = UIView()
                    faceFrameView.tag = i+1
                    if self.faceViews.count < i+1 {
                        self.faceViews.append(faceFrameView)
                    } else {
                        faceFrameView = self.faceViews[i]
                    }
                    faceFrameView.layer.borderColor = UIColor(red: CGFloat(115/255.0), green: CGFloat(93/255.0), blue: CGFloat(136/255.0), alpha: 1).cgColor
                    faceFrameView.layer.borderWidth = 4
                    faceFrameView.layer.cornerRadius = 5
                    
                    self.cameraView.addSubview(faceFrameView)
                    self.cameraView.bringSubview(toFront: faceFrameView)
                    faceFrameView.frame = faceRect
                }
            }
        }
        sleep(1)
    }
    
    func calculateFaceRect(faceBounds: CGRect, imgeSize: CGSize) -> CGRect {
        let parentFrameSize = videoPreviewLayer!.frame.size
        
        var faceRect = faceBounds
        
        let scaleBy = parentFrameSize.width / imgeSize.height
        
        faceRect.size.width *= scaleBy
        faceRect.size.height *= scaleBy
        faceRect.origin.x *= scaleBy
        faceRect.origin.y *= scaleBy
        
        let yOffset = (imgeSize.width * scaleBy - parentFrameSize.height) / 2

        let frame = CGRect(x:faceRect.origin.y , y: faceRect.origin.x - yOffset, width: faceRect.height, height: faceRect.width)

        return frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
