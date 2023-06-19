//  RotaryMenuView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 09/06/2023
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
import TariCommon

final class RotaryMenuView: UIView {

    struct MenuButtonViewModel: Identifiable {
        let id: UInt
        let icon: UIImage?
        let title: String?
    }

    private struct ButtonViewData {
        let index: Int
        let button: RotaryMenuButton
        let horizontalConstraint: NSLayoutConstraint
        let verticalConstraint: NSLayoutConstraint
    }

    // MARK: - Constants

    private let radius: CGFloat = 193.0
    private let angleStep: CGFloat = 0.4
    private let animationTime: TimeInterval = 0.4

    // MARK: - Subviews

    private var buttonData: [ButtonViewData] = []

    // MARK: - Properties

    var onButtonTap: ((UInt) -> Void)?

    // MARK: - Updates

    func update(buttonViewModels: [MenuButtonViewModel], iconLocation: RotaryMenuButton.IconLocation) {
        removeButtons()

        var buttonViewModels = buttonViewModels

        if iconLocation == .right {
            buttonViewModels.reverse()
        }

        buttonViewModels
            .enumerated()
            .forEach { addButton(model: $1, index: $0, iconLocation: iconLocation) }

        updateButtonsConstraints(iconLocation: iconLocation)
        updateButtonsWidth()
    }

    private func updateButtonsConstraints(iconLocation: RotaryMenuButton.IconLocation) {

        let angleOffset = CGFloat(buttonData.count - 1) * angleStep / 2.0
        var positionOffset: CGFloat = 0.0

        if iconLocation == .right {
            positionOffset = .pi
        }

        buttonData.forEach { data in

            let angle = CGFloat(data.index) * angleStep - angleOffset
            let xOffset = radius * cos(angle + positionOffset)
            let yOffset = radius * sin(angle + positionOffset)

            data.horizontalConstraint.constant = xOffset
            data.verticalConstraint.constant = yOffset

            DispatchQueue.main.async {
                data.button.transform = CGAffineTransform(rotationAngle: angle)
            }
        }
    }

    private func updateButtonsWidth() {
        let maxWidth = UIScreen.main.bounds.width - (bounds.width / 2.0) - 50.0

        buttonData
            .map(\.button)
            .forEach { $0.maxWidth = maxWidth }
    }

    private func addButton(model: MenuButtonViewModel, index: Int, iconLocation: RotaryMenuButton.IconLocation) {

        @View var button = RotaryMenuButton()

        button.icon = model.icon
        button.title = model.title
        button.iconLocation = iconLocation
        button.alpha = 0.0

        button.onTap = { [weak self] in
            self?.onButtonTap?(model.id)
        }

        addSubview(button)

        let horizontalConstraint = button.iconView.centerXAnchor.constraint(equalTo: centerXAnchor)
        let verticalConstraint = button.iconView.centerYAnchor.constraint(equalTo: centerYAnchor)

        NSLayoutConstraint.activate([horizontalConstraint, verticalConstraint])

        let data = ButtonViewData(index: index, button: button, horizontalConstraint: horizontalConstraint, verticalConstraint: verticalConstraint)
        buttonData.append(data)
    }

    private func removeButtons() {
        buttonData.forEach { $0.button.removeFromSuperview() }
        buttonData.removeAll()
    }

    // MARK: - Actions

    func show() async {
        await updateButtons(alpha: 1.0)
    }

    func hide() async {
        await updateButtons(alpha: 0.0)
    }

    private func updateButtons(alpha: CGFloat) async {

        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }

            self.buttonData.enumerated().forEach { index, data in

                let button = data.button
                let delay = TimeInterval(index) * self.animationTime / 6.0

                UIView.animate(withDuration: self.animationTime, delay: delay, animations: {
                    button.alpha = alpha
                }, completion: { _ in
                    guard self.buttonData.count == index + 1 else { return }
                    continuation.resume()
                })
            }
        }
    }

    // MARK: - Touches

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let view = subviews.first {
            let convertedPoint = $0.convert(point, from: self)
            return $0.point(inside: convertedPoint, with: event)
        }

        return view != nil
    }

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateButtonsWidth()
    }
}
