//  QRImage.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 30.10.2025
	Using Swift 6.0
	Running on macOS 26.0

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

import SwiftUI
import QRCode

public struct QRImage: View {
    let document: QRCode.Document?
    
    public init(_ value: String, colors: [Color] = [.black, .black], backgroundColor: Color = .white) {
        if let document = try? QRCode.Document(utf8String: value) {
            document.design.shape.eye = QRCode.EyeShape.Square()
            document.design.shape.onPixels = QRCode.PixelShape.Square()
            let gradientPins = colors.enumerated().map {
                DSFGradient.Pin(UIColor($1).cgColor, CGFloat($0 / max(1, (colors.count - 1))))
            }
            if let gradient = try? DSFGradient(pins: gradientPins) {
                document.design.style.onPixels = QRCode.FillStyle.LinearGradient(gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 1, y: 1)
                )
            }
            self.document = document
        } else {
            self.document = nil
        }
    }
    
    public var body: some View {
        if let document {
            QRCodeDocumentUIView(document: document)
        }
    }
}
