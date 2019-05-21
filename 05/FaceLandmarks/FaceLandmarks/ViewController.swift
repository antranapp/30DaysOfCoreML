//
//  Copyright © 2019 An Tran. All rights reserved.
//

import UIKit
import Vision
import CoreML
import ImageIO

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectImageButton: UIBarButtonItem!

    @IBAction func didTapSelectImageButton(_ sender: Any) {
        selectImage()
    }

    var selectedImage: UIImage!

    private func processImage() {
        guard let cgImage = selectedImage.cgImage else {
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            let request = VNDetectFaceLandmarksRequest(completionHandler: handleFaceLandmarksDetection(request:error:))
            try handler.perform([request])
        } catch {
            print(error)
        }
    }

    private func handleFaceLandmarksDetection(request: VNRequest, error: Error?) {

        guard let observations = request.results as? [VNFaceObservation] else {
            print("no observation found")
            return
        }

        print("Found \(observations.count) faces")

        for observation in observations {
            let landmarkRegions = findFaceFeatures(forObservation: observation)
            selectedImage = drawFaceLandmarks(image: selectedImage, boundingBox: observation.boundingBox, faceLandmarkRegions: landmarkRegions)
        }

        imageView.image = selectedImage
    }

    private func drawFaceLandmarks(image: UIImage, boundingBox: CGRect, faceLandmarkRegions: [VNFaceLandmarkRegion2D]) -> UIImage? {

        defer {
            UIGraphicsEndImageContext()
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, 1)

        guard let cgImage = image.cgImage else {
            print("failed to get cgImage")
            return nil
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            print("failed to get graphics context")
            return nil
        }

        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        let rectWidth = image.size.width * boundingBox.size.width
        let rectHeight = image.size.height * boundingBox.size.height

        // Draw original image
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        context.draw(cgImage, in: imageRect)

        // Draw bounding box
        context.setLineWidth(4.0)
        context.setStrokeColor(UIColor.red.cgColor)
        let boundingBoxRect = CGRect(x: boundingBox.origin.x * image.size.width, y: boundingBox.origin.y * image.size.height, width: rectWidth, height: rectHeight)
        context.addRect(boundingBoxRect)
        context.drawPath(using: .stroke)

        // Draw overlay
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.blue.cgColor)
        //context.setBlendMode(CGBlendMode.colorBurn)
        for faceLandmarkRegion in faceLandmarkRegions {
            var points: [CGPoint] = []
            for i in 0..<faceLandmarkRegion.pointCount {
                let point = faceLandmarkRegion.normalizedPoints[i]
                let p = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                points.append(p)
            }
            let mappedPoints = points.map { CGPoint(x: boundingBox.origin.x * image.size.width + $0.x * rectWidth, y: boundingBox.origin.y * image.size.height + $0.y * rectHeight) }
            context.addLines(between: mappedPoints)
            context.drawPath(using: CGPathDrawingMode.stroke)
        }

        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("failed to get result image from current context")
            return nil
        }

        return resultImage
    }

    private func findFaceFeatures(forObservation face: VNFaceObservation) -> [VNFaceLandmarkRegion2D] {

        guard let landmarks = face.landmarks else {
            return []
        }

        var landmarkRegions = [VNFaceLandmarkRegion2D]()

        if let faceContour = landmarks.faceContour {
            landmarkRegions.append(faceContour)
        }

        if let leftEye = landmarks.leftEye {
            landmarkRegions.append(leftEye)
        }

        if let rightEye = landmarks.rightEye {
            landmarkRegions.append(rightEye)
        }

        if let nose = landmarks.nose {
            landmarkRegions.append(nose)
        }

        if let noseCrest = landmarks.noseCrest {
            landmarkRegions.append(noseCrest)
        }

        if let medianLine = landmarks.medianLine {
            landmarkRegions.append(medianLine)
        }

        if let outerLips = landmarks.outerLips {
            landmarkRegions.append(outerLips)
        }

        if let leftEyebrow = landmarks.leftEyebrow {
            landmarkRegions.append(leftEyebrow)
        }

        if let rightEyebrow = landmarks.rightEyebrow {
            landmarkRegions.append(rightEyebrow)
        }

        if let innerLips = landmarks.innerLips {
            landmarkRegions.append(innerLips)
        }

        if let leftPupil = landmarks.leftPupil {
            landmarkRegions.append(leftPupil)
        }

        if let rightPupil = landmarks.rightPupil {
            landmarkRegions.append(rightPupil)
        }

        return landmarkRegions
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }

        selectedImage = image
        imageView.image = selectedImage

        processImage()
    }
}
