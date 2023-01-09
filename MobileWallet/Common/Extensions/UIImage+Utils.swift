//  UIImage+Utils.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/06/2022
	Using Swift 5.0
	Running on macOS 12.3

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

extension UIImage {

    var invertedMask: UIImage? {
        guard let ciImage = CIImage(image: self),
              let backgroundImage = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: CIColor.black])?.outputImage,
              let forgroundImage = CIFilter(name: "CIConstantColorGenerator", parameters: [kCIInputColorKey: CIColor.clear])?.outputImage,
              let image = CIFilter(name: "CIBlendWithAlphaMask", parameters: [kCIInputImageKey: forgroundImage, kCIInputBackgroundImageKey: backgroundImage, kCIInputMaskImageKey: ciImage])?.outputImage,
              let cgImage = CIContext().createCGImage(image, from: CGRect(x: 0.0, y: 0.0, width: size.width * scale, height: size.height * scale))
        else { return nil }

        return UIImage(cgImage: cgImage)
    }

    func image(withSize updatedSize: CGSize) -> UIImage? {

        let xOrigin = (updatedSize.width - size.width) / 2.0
        let yOrigin = (updatedSize.height - size.height) / 2.0

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        return UIGraphicsImageRenderer(size: updatedSize, format: format).image { _ in
            draw(in: CGRect(origin: CGPoint(x: xOrigin, y: yOrigin), size: size))
        }
    }
}
