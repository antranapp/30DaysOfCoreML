//
//  Copyright © 2019 An Tran. All rights reserved.
//

import UIKit

class DrawView: UIView {

    var lineWidth = CGFloat(15) {
        didSet {
            setNeedsDisplay()
        }
    }

    var color = UIColor.white {
        didSet {
            setNeedsDisplay()
        }
    }

    var lines = [Line]()
    var lastPoint: CGPoint!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPoint = touches.first!.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let newPoint = touches.first!.location(in: self)
        lines.append(Line(start: lastPoint, end: newPoint))
        lastPoint = newPoint
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let drawPath = UIBezierPath()
        drawPath.lineCapStyle = .round

        for line in lines {
            drawPath.move(to: line.start)
            drawPath.addLine(to: line.end)
        }

        drawPath.lineWidth = lineWidth
        color.set()
        drawPath.stroke()
    }

    func getViewContext() -> CGContext? {
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()

        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        let context = CGContext(data: nil, width: 28, height: 28, bitsPerComponent: 8, bytesPerRow: 28, space: colorSpace, bitmapInfo: bitmapInfo) as! CGContext

        context.translateBy(x: 0, y: 28)
        context.scaleBy(x: 28/frame.size.width, y: -28/frame.size.height)

        layer.render(in: context)

        return context
    }
}

struct Line {
    var start: CGPoint
    var end: CGPoint
}
