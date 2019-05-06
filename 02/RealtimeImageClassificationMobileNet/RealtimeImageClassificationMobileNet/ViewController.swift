//
//  Copyright © 2019 An Tran. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var classifierLabel: UILabel!

    let model = MobileNet()
    lazy var classificationRequest: VNCoreMLRequest = {
        guard let request = makeClassificationRequest() else {
            fatalError("failed to load vision ML model")
        }

        return request
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)

        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        cameraView.layer.addSublayer(previewLayer)

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutputQueue"))
        captureSession.addOutput(dataOutput)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        performClassification(pixelBuffer)
    }

    func makeClassificationRequest() -> VNCoreMLRequest? {
        guard let model = try? VNCoreMLModel(for: model.model) else { return nil }

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            self?.processClassifications(for: request, error: error)
        }

        request.imageCropAndScaleOption = .centerCrop
        return request
    }

    func performClassification(_ pixelBuffer: CVPixelBuffer) {
        guard let classificationRequest = makeClassificationRequest() else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([classificationRequest])
            } catch {          
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }

    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNClassificationObservation] else { return }

            guard let firstObservation = results.first else { return }

            self.classifierLabel.text = "\(firstObservation.identifier) (\(firstObservation.confidence))"
        }
    }
}

