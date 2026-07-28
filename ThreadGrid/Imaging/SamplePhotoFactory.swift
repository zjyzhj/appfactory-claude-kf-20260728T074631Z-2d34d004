import Foundation
import UIKit
import CoreGraphics

/// Deterministic sample photo used by the Simulator capture seam: Simulators
/// have no camera hardware, so after a granted permission the app produces this
/// deterministic synthetic photo to prove the full permission → capture → bind
/// journey end to end (checklist §12). Real devices use the camera instead.
enum SamplePhotoFactory {

    static func makeStitchSample(size: CGSize = CGSize(width: 900, height: 1200)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let context = ctx.cgContext
            // Meadow backdrop.
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor(hexString: "#BFD7A8").cgColor, UIColor(hexString: "#7E9446").cgColor] as CFArray,
                locations: [0, 1]
            )!
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            // Sun.
            UIColor(hexString: "#FFD069").setFill()
            context.fillEllipse(in: CGRect(x: size.width * 0.62, y: size.height * 0.10, width: 160, height: 160))

            // Fox body — simple geometric shapes with strong color blocks that
            // quantize into a recognizable stitched creature.
            let foxOrange = UIColor(hexString: "#E16A3A")
            let foxCream = UIColor(hexString: "#F7E9D0")
            let dark = UIColor(hexString: "#2B2118")

            foxOrange.setFill()
            context.fillEllipse(in: CGRect(x: size.width * 0.22, y: size.height * 0.42, width: size.width * 0.56, height: size.height * 0.30))

            // Ears.
            let leftEar = UIBezierPath()
            leftEar.move(to: CGPoint(x: size.width * 0.30, y: size.height * 0.44))
            leftEar.addLine(to: CGPoint(x: size.width * 0.36, y: size.height * 0.32))
            leftEar.addLine(to: CGPoint(x: size.width * 0.44, y: size.height * 0.43))
            leftEar.close()
            foxOrange.setFill()
            leftEar.fill()
            let rightEar = UIBezierPath()
            rightEar.move(to: CGPoint(x: size.width * 0.56, y: size.height * 0.43))
            rightEar.addLine(to: CGPoint(x: size.width * 0.64, y: size.height * 0.32))
            rightEar.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.44))
            rightEar.close()
            rightEar.fill()

            // Face + muzzle.
            foxCream.setFill()
            context.fillEllipse(in: CGRect(x: size.width * 0.36, y: size.height * 0.52, width: size.width * 0.28, height: size.height * 0.16))

            // Eyes + nose.
            dark.setFill()
            context.fillEllipse(in: CGRect(x: size.width * 0.40, y: size.height * 0.50, width: 26, height: 26))
            context.fillEllipse(in: CGRect(x: size.width * 0.56, y: size.height * 0.50, width: 26, height: 26))
            context.fillEllipse(in: CGRect(x: size.width * 0.475, y: size.height * 0.60, width: 30, height: 22))

            // Flowers.
            let flowerColors = ["#C0453E", "#3E5F8A", "#C8842C", "#E56A8B"]
            for i in 0..<10 {
                let fx = size.width * (0.08 + 0.09 * CGFloat(i % 6))
                let fy = size.height * (0.82 + 0.05 * CGFloat(i % 3))
                UIColor(hexString: flowerColors[i % flowerColors.count]).setFill()
                context.fillEllipse(in: CGRect(x: fx, y: fy, width: 34, height: 34))
                UIColor(hexString: "#FFD069").setFill()
                context.fillEllipse(in: CGRect(x: fx + 10, y: fy + 10, width: 14, height: 14))
            }
        }
    }
}
