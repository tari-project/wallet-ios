//  CircularProgressView.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 10.06.2020
	Using Swift 5.0
	Running on macOS 10.15

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
class CircularProgressView: UIView {

    private var circleLayer = CAShapeLayer()
    private var progressLayer = CAShapeLayer()

    var circleLayerColor: UIColor = Theme.shared.colors.settingsTableStyleBackground! {
        didSet {
            circleLayer.strokeColor = circleLayerColor.cgColor
        }
    }

    var circleLayerLineWidth: CGFloat = 4.0 {
        didSet {
            circleLayer.lineWidth = circleLayerLineWidth
        }
    }

    var progressLayerColor: UIColor = Theme.shared.colors.checkBoxBorderColor! {
        didSet {
            progressLayer.strokeColor = progressLayerColor.cgColor
        }
    }

    var progressLayerLineWidth: CGFloat = 2.0 {
        didSet {
            progressLayer.lineWidth = progressLayerLineWidth
        }
    }

    override func draw(_ rect: CGRect) {
        createCircularPath()
    }

    func createCircularPath() {
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: frame.height/2 - circleLayerLineWidth/2, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)

        circleLayer.path = circularPath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineCap = .round
        circleLayer.lineWidth = circleLayerLineWidth
        circleLayer.strokeColor = circleLayerColor.cgColor

        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressLayerColor.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = progressLayerLineWidth
        progressLayer.strokeEnd = 0

        layer.addSublayer(circleLayer)
        layer.addSublayer(progressLayer)
    }

    func setProgress(_ progress: Double) {
        let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circularProgressAnimation.duration = CATransaction.animationDuration()
        circularProgressAnimation.fromValue = progressLayer.strokeEnd
        circularProgressAnimation.toValue = CGFloat(progress)
        circularProgressAnimation.fillMode = .forwards
        circularProgressAnimation.isRemovedOnCompletion = false
        progressLayer.add(circularProgressAnimation, forKey: "progressAnim")
        progressLayer.strokeEnd = CGFloat(progress)
    }
}
