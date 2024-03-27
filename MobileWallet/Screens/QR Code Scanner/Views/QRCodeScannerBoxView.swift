//  QRCodeScannerBoxView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 12/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class QRCodeScannerBoxView: UIView {

    // MARK: - Subvies

    private let borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.Static.white.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 10.0
        layer.lineCap = .round
        layer.lineJoin = .round
        return layer
    }()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupLayers() {
        layer.addSublayer(borderLayer)
    }

    // MARK: - Updates

    private func updateBorderLayer() {

        let path = UIBezierPath()
        let lineLenght = min(bounds.width, bounds.height) * 0.25

        path.move(to: CGPoint(x: bounds.minX, y: bounds.minY + lineLenght))
        path.addLine(to: CGPoint(x: bounds.minY, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.minY + lineLenght, y: bounds.minY))
        path.move(to: CGPoint(x: bounds.maxX - lineLenght, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY + lineLenght))
        path.move(to: CGPoint(x: bounds.maxX, y: bounds.maxY - lineLenght))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.maxX - lineLenght, y: bounds.maxY))
        path.move(to: CGPoint(x: bounds.minX + lineLenght, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY - lineLenght))

        borderLayer.path = path.cgPath
    }

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.bounds = bounds
        updateBorderLayer()
    }
}
