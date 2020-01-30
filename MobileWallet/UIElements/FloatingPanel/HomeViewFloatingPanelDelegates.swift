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
    let navBarHeight: CGFloat
    let initialFullScreen: Bool

    init(navBarHeight: CGFloat, initialFullScreen: Bool) {
        self.navBarHeight = navBarHeight
        self.initialFullScreen = initialFullScreen
    }

    var positionReference: FloatingPanelLayoutReference {
        return .fromSuperview
    }

    public var initialPosition: FloatingPanelPosition {
        return initialFullScreen ? .full : .tip
    }

    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        let topInset: CGFloat = navBarHeight - 2
        let lowestHeight = UIScreen.main.bounds.height - 190

        switch position {
            case .full: return topInset // A top inset from safe area
            case .tip: return lowestHeight // A bottom inset from the safe area
            default: return nil // Or `case .hidden: return nil`
        }
    }

    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        if position == .full {
            //TODO refactor to allow for backdrop being set from HomeViewController
            return 0.0
        }

        return 0.0
    }
}

class HomeViewFloatingPanelBehavior: FloatingPanelBehavior {
    func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        return false
    }

    func shouldProjectMomentum(_ fpc: FloatingPanelController, for proposedTargetPosition: FloatingPanelPosition) -> Bool {
        return false
    }
}
