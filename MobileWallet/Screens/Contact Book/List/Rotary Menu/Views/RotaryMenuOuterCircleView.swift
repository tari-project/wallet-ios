//  RotaryMenuOuterCircleView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 19/06/2023
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

final class RotaryMenuOuterCircleView: UIView {

    // MARK: - Layers

    private let shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.Static.white.withAlphaComponent(0.8).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1.0
        layer.lineCap = .round
        layer.lineJoin = .round
        return layer
    }()

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updatePath() {

        let path = UIBezierPath()
        let radius = bounds.height / 2.0
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)

        path.addQuaterCirtle(centerPoint: centerPoint, radius: radius, normalizedAngle: 0.0, clockwise: true)
        path.addQuaterCirtle(centerPoint: centerPoint, radius: radius, normalizedAngle: 90.0, clockwise: false)
        path.addQuaterCirtle(centerPoint: centerPoint, radius: radius, normalizedAngle: 180.0, clockwise: true)
        path.addQuaterCirtle(centerPoint: centerPoint, radius: radius, normalizedAngle: 270.0, clockwise: false)

        shapeLayer.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
        shapeLayer.frame = bounds
    }
}

private extension UIBezierPath {

    func addQuaterCirtle(centerPoint: CGPoint, radius: CGFloat, normalizedAngle: CGFloat, clockwise: Bool) {

        var angles = [0.0, 13.0, 17.0, 20.0, 22.0, 90.0]

        if clockwise {
            angles = angles.map { normalizedAngle + $0 }
        } else {
            angles = angles.map { normalizedAngle + 90.0 - $0 }
        }

        move(to: centerPoint.point(distance: .point(radius: radius, normalizedDegrees: angles[0])))
        addArc(withCenter: centerPoint, radius: radius, startAngle: .angle(normalizedDegrees: angles[0]), endAngle: .angle(normalizedDegrees: angles[1]), clockwise: clockwise)
        addArrow(tipPoint: centerPoint.point(distance: .point(radius: radius, normalizedDegrees: angles[2])), normalizedDegrees: angles[2], clockwise: clockwise)
        addArrow(tipPoint: centerPoint.point(distance: .point(radius: radius, normalizedDegrees: angles[3])), normalizedDegrees: angles[3], clockwise: clockwise)
        move(to: centerPoint.point(distance: .point(radius: radius, normalizedDegrees: angles[4])))
        addArc(withCenter: centerPoint, radius: radius, startAngle: .angle(normalizedDegrees: angles[4]), endAngle: .angle(normalizedDegrees: angles[5]), clockwise: clockwise)
    }

    private func addArrow(tipPoint: CGPoint, normalizedDegrees: CGFloat, clockwise: Bool) {

        let arrowAngle: CGFloat = 45.0
        let shiftAngle: CGFloat = 90.0 * (clockwise ? -1.0 : 1.0)

        let firstArmPoint: CGPoint = .point(radius: 9.0, normalizedDegrees: normalizedDegrees - arrowAngle + shiftAngle)
        let secondArmPoint: CGPoint = .point(radius: 9.0, normalizedDegrees: normalizedDegrees + arrowAngle + shiftAngle)

        move(to: tipPoint)
        addLine(to: tipPoint.point(distance: firstArmPoint))
        move(to: tipPoint)
        addLine(to: tipPoint.point(distance: secondArmPoint))
        move(to: tipPoint)
    }
}
