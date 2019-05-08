//
//  Copyright © 2019 An Tran. All rights reserved.
//

import UIKit
import CoreML
import CoreImage

class ViewController: UIViewController {

    @IBOutlet weak var drawView: DrawView!
    @IBOutlet weak var predictLabel: UILabel!

    let model = MNIST()
    let context = CIContext()
    var pixelBuffer: CVPixelBuffer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault,
                            28,
                            28,
                            kCVPixelFormatType_OneComponent8,
                            attrs,
                            &pixelBuffer)
    }


    @IBAction func didTapDetect(_ sender: Any) {
        let viewContext = drawView.getViewContext()
        let cgImage = viewContext?.makeImage()
        let ciImage = CIImage(cgImage: cgImage!)
        context.render(ciImage, to: pixelBuffer!)

        guard let output = try? model.prediction(image: pixelBuffer!) else {
            return
        }

        predictLabel.text = "\(output.classLabel)"
    }

    @IBAction func didTapClear(_ sender: Any) {
        drawView.lines = []
        drawView.setNeedsDisplay()
        predictLabel.text = nil
    }
}

