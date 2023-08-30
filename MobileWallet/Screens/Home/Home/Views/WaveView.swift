//  WaveView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 04/07/2023
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

import TariCommon

final class WaveView: UIView {

    // MARK: - Constants

    private let waveWidthScale = 2.5
    private let waveAmplitude = 0.06

    // MARK: - Subviews

    private let shapeLayer = CAShapeLayer()
    @View private var gradientView = TariGradientView()

    // MARK: - Properties

    private var isAnimating: Bool = false

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupLayers()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupLayers() {
        shapeLayer.strokeColor = UIColor.black.cgColor
        layer.mask = shapeLayer
    }

    private func setupConstraints() {

        addSubview(gradientView)

        let constraints = [
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    private func updateShapeLayerPath() {

        let width = bounds.width
        let height = bounds.height

        let origin = CGPoint(x: 0.0, y: height * 0.2)

        let path = UIBezierPath()
        path.move(to: origin)

        let step = 5.0

        stride(from: step, to: step * step * width, by: step).forEach {
            let x = origin.x + CGFloat($0 / 360.0) * width * waveWidthScale
            let y = origin.y - CGFloat(sin($0 / 180.0 * .pi)) * height * waveAmplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width * waveWidthScale + width, y: 0.0))
        path.addLine(to: CGPoint(x: width * waveWidthScale + width, y: height))
        path.addLine(to: CGPoint(x: 0.0, y: height))
        path.addLine(to: CGPoint(x: 0.0, y: origin.y))

        shapeLayer.path = path.cgPath
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        updateShapeLayerPath()
    }

    // MARK: - Actions

    func startAnimation() {

        let endPosition = CGPoint(x: -bounds.width * waveWidthScale, y: 0.0)
        guard endPosition.x < 0.0 else { return }

        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = CGPoint.zero
        animation.toValue = endPosition
        animation.duration = 10.0

        animation.onCompletion = { [weak self] finished in
            guard finished, self?.isAnimating == true else { return }
            self?.startAnimation()
        }

        shapeLayer.add(animation, forKey: nil)
        isAnimating = true
    }

    func stopAnimation() {
        isAnimating = false
        shapeLayer.removeAllAnimations()
    }
}
