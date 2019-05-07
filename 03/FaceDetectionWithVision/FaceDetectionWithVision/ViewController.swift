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
        let alertController = UIAlertController(title: "Import picture", message: nil, preferredStyle: .actionSheet)
        let galleryButton = UIAlertAction(title: "Photo Library", style: .default, handler: { [unowned self] _ in
            self.presentImageController(from: .photoLibrary)
        })
        let pictureButton = UIAlertAction(title: "Camera", style: .default, handler: { [unowned self] _ in
            self.presentImageController(from: .camera)
        })
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(galleryButton)
        alertController.addAction(pictureButton)
        alertController.addAction(cancelButton)

        present(alertController, animated: true, completion: nil)
    }

    func presentImageController(from source: UIImagePickerController.SourceType) {
        let viewController = UIImagePickerController()
        viewController.sourceType = source
        viewController.delegate = self
        self.present(viewController, animated: true, completion: nil)
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
        DispatchQueue.main.async { [weak self] in
            guard let observations = request.results as? [VNFaceObservation] else {
                fatalError("unexpected result type!")
            }

            print("Detected \(observations.count) faces")

            observations.forEach { self?.addFaceRecognitionLayer($0) }
        }
    }

    func addFaceRecognitionLayer(_ face: VNFaceObservation) {

        guard let image = imageView.image else { return }

        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()

        // draw the image
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))

        // draw line
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -image.size.height)
        let translate = CGAffineTransform.identity.scaledBy(x: image.size.width, y: image.size.height)
        let facebounds = face.boundingBox.applying(translate).applying(transform)

        context?.saveGState()
        context?.setStrokeColor(UIColor.red .cgColor)
        context?.setLineWidth(5.0)
        context?.addRect(facebounds)
        context?.drawPath(using: .stroke)
        context?.restoreGState()

        // get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()

        // end drawing context
        UIGraphicsEndImageContext()

        imageView.image = finalImage
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            startDetection(image: image)
        }

        picker.dismiss(animated: true, completion: nil)
    }
}
