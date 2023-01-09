//  UIColor+Utils.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/06/2022
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

extension UIColor {

    func colorVariant(text: String) -> UIColor {

        let delta: CGFloat = 0.1

        var hue: CGFloat = -1
        var saturation: CGFloat = -1
        var brightness: CGFloat = -1
        var alpha: CGFloat = -1

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let hash = text.hash

        let saturationRange = range(center: saturation, delta: delta)
        let brightnessRange = range(center: brightness, delta: delta)

        let saturationScale = CGFloat((hash & 0xFF00) >> 8) / 256.0
        let brightnessScale = CGFloat((hash & 0xFF) >> 0) / 256.0

        let saturationVariant = saturationRange.upperBound - (saturationRange.upperBound - saturationRange.lowerBound) * saturationScale
        let brightnessVariant = brightnessRange.upperBound - (brightnessRange.upperBound - brightnessRange.lowerBound) * brightnessScale

        return UIColor(hue: hue, saturation: saturationVariant, brightness: brightnessVariant, alpha: alpha)
    }

    private func range(center: CGFloat, delta: CGFloat) -> ClosedRange<CGFloat> {
        switch center {
        case (1.0 - delta)...CGFloat.greatestFiniteMagnitude:
            return (1.0 - delta * 2.0)...1.0
        case CGFloat.leastNormalMagnitude...delta:
            return 0.0...(delta * 2.0)
        default:
            return (center - delta)...(center + delta)
        }
    }
}
