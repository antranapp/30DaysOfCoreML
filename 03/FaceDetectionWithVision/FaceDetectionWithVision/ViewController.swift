//
//  Copyright © 2019 An Tran. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!

    lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest(completionHandler: { [weak self] (request, error) in
            self?.handleDetection(request: request, error: error)
        })
        return request
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func didTapSelectImage(_ sender: Any) {
    }

    func startDetection(image: UIImage) {
        let orientation = image.coreOrientation()
        guard let coreImage = CIImage(image: image) else { return }

        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(ciImage: coreImage, orientation: orientation, options: [:])
            do {
                try handler.perform([self.faceDetectionRequest])
            } catch {
                print("Failed to perform detection: \(error.localizedDescription)")
            }
        }
    }

    func handleDetection(request: VNRequest, error: Error?) {

    }

    func addFaceRecognitionLayer(_ face: VNFaceObservation) {

    }
}

