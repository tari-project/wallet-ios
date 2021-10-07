//  CustomFloatingPanelLayout.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2019/10/31
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

import Foundation
import FloatingPanel

class HomeViewFloatingPanelLayout: FloatingPanelLayout {
    static let bottomHalfSurfaceViewInsets: UIEdgeInsets = UIEdgeInsets(top: 37, left: 0, bottom: 116 + UIApplication.shared.windows[0].safeAreaInsets.bottom, right: 0)

    let navBarHeight: CGFloat

    init(navBarHeight: CGFloat) {
        self.navBarHeight = navBarHeight
    }

    var positionReference: FloatingPanelLayoutReference {
        return .fromSuperview
    }

    public var initialPosition: FloatingPanelPosition {
        return .hidden
    }

    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        let topInset: CGFloat = navBarHeight
        // Raising the lowest postion of the panel slightly for phones without the notch
        let lowestHeight = UIScreen.main.bounds.height - 106.0 - (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0)

        switch position {
            case .full: return topInset - 37 // A top inset from safe area
            case .half: return lowestHeight // A bottom inset from the safe area
            default: return nil // Or `case .hidden: return nil`
        }
    }
}
