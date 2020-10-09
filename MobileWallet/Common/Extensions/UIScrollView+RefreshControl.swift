//  UIScrollView+RefreshControl.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 29.05.2020
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

extension UIScrollView {

    func beginRefreshing() {
        if isRefreshing() { return }
        refreshControl?.programaticallyBeginRefreshing(in: self)
    }

    func endRefreshing() {
        if !isRefreshing() { return }
        stopDecelerating()
        // animated for fix blinking during end refresh
        UIView.transition(with: self,
                          duration: CATransaction.animationDuration(),
                          options: .transitionCrossDissolve,
                          animations: {
                            self.refreshControl?.endRefreshing()
                          },
                          completion: { (_) in
                            if self.contentOffset.y < 0 {
                                self.scrollToTop(animated: true)
                            }})
    }

    func isRefreshing() -> Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    func scrollToBottom(animated: Bool) {
        let yOffset = contentSize.height - bounds.size.height
        let bottomOffset = CGPoint(x: 0, y: yOffset > 0 ? yOffset : 0)
        setContentOffset(bottomOffset, animated: animated)
    }

    func scrollToTop(animated: Bool) {
        let y = 0.0  - contentInset.top
        setContentOffset(CGPoint(x: 0.0, y: y), animated: animated)
    }

    func lockScrollView() {
        isDirectionalLockEnabled = true
        bounces = false
        showsVerticalScrollIndicator = false
    }

    func unlockScrollView() {
        isDirectionalLockEnabled = false
        bounces = true
        showsVerticalScrollIndicator = true
    }

    func stopDecelerating() {
         setContentOffset(contentOffset, animated: false)
    }
}

extension UIRefreshControl {
    func programaticallyBeginRefreshing(in scrollView: UIScrollView) {
        beginRefreshing()
        let yOffset = height()
        let offsetPoint = CGPoint.init(x: 0, y: -yOffset)
        scrollView.setContentOffset(offsetPoint, animated: true)
        sendActions(for: .valueChanged)
    }

    func height() -> CGFloat {
        return frame.size.height >= 80 ? frame.size.height : 80
    }
}
